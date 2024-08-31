#H3BR making function
library(data.table)
library(sf)
library(h3)
library(tidyverse)
library(tibble)
library(igraph)

source(file = "R/Core_H3BR_function.R")
source(file = "R/iteration_functions.R")

tl <- Sys.time()

data <- st_read("data/MSOA_3_subset/MSOA_3_subset.shp") # 5 columns containing H310 indexes with key information, in the order below
colnames(data) <- c("region", "topo_code", "h3_10", "activity", "geometry") #region= MSOA codes, topo_code=terrain identifier, h3_10= h3 index, activity= count of point per h310, geometry= h310 geometry
data[is.na(data)] <- 0
data$h3_10_char <- as.character(data$h3_10)
splitdata <- group_split(data, region)#split the data by MSOA to run following MSOA by MSOA

# for-loop to run recursively through the MSOA groups. relies on source functions, especially for iteration.
output <- NULL
for (M in splitdata) {
  
  G <- h3_based_regionalisation(M) #G = groups, M = MSOA, as this function takes in MSOAs and returns group membership for its H310s
  
  colnames(G) <- c("h3_10_char", "group")
  G <- left_join(M, G)
  G <- st_drop_geometry(G)
  G <- as.data.frame(G)
  G$group <- ifelse(is.na(G$group), sample(c(1500:800000), 
                                           length(is.na(G$group)), 
                                           replace = TRUE), G$group) #assigns a random number id to hexagons that do not merge
  G <- G %>%
    group_by(group) %>%
    mutate(group_activity = sum(activity)) %>%
    ungroup()
  colnames(G)[colnames(G) == "h3_10_char"] <- "i"
  
  # initialise variables to track iterations and changes for the iterative regrouping
  changes_made <- TRUE
  iteration_count <- 0
  same_count_iterations <- 0
  prev_under_threshold_count <- -1
  
  while (changes_made) {
    changes_made <- FALSE # assume no changes will be made in this iteration
    iteration_count <- iteration_count + 1
    hex_to_recombine <- G %>% filter(group_activity < 10)
    under_threshold_count <- nrow(hex_to_recombine)
    
    # log the iteration and the number of hexagons under threshold
    cat("Iterations: ", iteration_count, " - Hexagons under threshold: ", under_threshold_count, "\n")
    
    if (under_threshold_count == 0) {
      break # exit loop if no hex under threshold
    }
    
    # check if the count of hexagons under threshold is the same as previous iteration
    if (under_threshold_count == prev_under_threshold_count) {
      same_count_iterations <- same_count_iterations + 1
      
      # Exit the loop if the count has been the same for 5 consecutive iterations
      if (same_count_iterations >= 5) {
        cat("The number of hexagons under threshold has remained the same for 5 consecutive iterations. Stopping...\n")
        break
      }
    } else {
      same_count_iterations <- 0 # reset counter if the count has changed
    }
    
    prev_under_threshold_count <- under_threshold_count # update previous count for the next iteration
    
    for (hex_id in hex_to_recombine) {
      best_group <- select_best_group(hex_id, G)
      
      if (!is.null(best_group)) {
        # check if this hex's group is actually changing
        if (G[G$hex_id == hex_id, ]$group != best_group) {
          changes_made <- TRUE # mark that a change was made
        } 
        G <- G %>% 
          mutate(group = ifelse(hex_id == hex_id, best_group, group))
      }
    }
  
  # update group activities after each round of reassignment
  G <- update_groups(G)
  
  # check if any reassignments were made; if not, exit the loop to prevent infinite loop
  if (!changes_made) {
    cat("No changes made in the last iteration. Stopping...\n")
    break
  }
}
    output <- rbind(G, output)  
}
 
output <- as.data.frame(output)
output <- select(output, c(5, 6, 7))
colnames(output) <- c("h3_10_char", "group", "group_activity")
output <- left_join(data, output)
  
# combine the group with region code to create unique region code
output$region_code <- paste0(output$region, "_", output$group)
  
# MERGE GROUPS OUTPUTTED FROM FUNCTION INTO REGIONS
merged_regions_london <- output %>%
  group_by(region_code) %>%
  summarise(geometry = st_union(geometry)) %>%
  ungroup()
  
t2 <- Sys.time()
st_write(merged_regions_london, dsn = "H3BR_output.shp", driver = 'ESRI Shapefile')
print(t2 - t1)
