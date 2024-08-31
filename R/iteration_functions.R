# Function to get neighbours and their details if 2nd iteration required

get_n_details <- function(hex_id, df) {
  n <- k_ring(hex_id, radius = 1)
  n <- n[n != hex_id]
  n_details <- df %>% filter(i %in% n)
  return(n_details)
}

# Function to select the best group for merging when needing to regroup

select_best_group <- function(hex_id, df) {
  current_hex <- df %>% filter(i == hex_id)
  n_details <- get_n_details(hex_id, df)
  
  # filter for different groups to avoid merging within the same group
  different_groups <- n_details %>% filter(group != current_hex$group)
  
  if(nrow(different_groups) == 0) return(NULL) # no different groups available
  
  # prioritise same topo code, then highest group_activity
  best_group <- different_groups %>%
    mutate(same_topo = topo_code == current_hex$topo_code,
           priority = ifelse(same_topo, 1, 1)) %>%
    arrange(desc(priority), desc(group_activity)) %>%
    slice(1) %>%
    pull(group)
  
  return(best_group)
}

# Function to update group assignments and activities for iteration

update_groups <- function(df) {
  df <- df %>%
    group_by(group) %>%
    mutate(group_activity = sum(activity)) %>%
    ungroup()
  return(df)
}
