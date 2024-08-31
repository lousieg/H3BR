#core function finds hexes <10 and combines them with a preferred neighbour (community detection for ranked interconnected neighbor groups) - makes the PNMx (only one iteration)
h3_based_regionalisation <- function(M) {
  
  #list H310s of ativity < 10
  list_sub10 <- M$h3_10_char[M$activity < 10]
  inter <- matrix(ncol = 2, nrow = 0, dimnames = list(NULL, c("i", "n")))
  df <- matrix(ncol = 2, nrow = 0, dimnames = list(NULL, c("i", "n")))
  
  #for each H310 < 10, retrieve it's neighbours and name them 'n'
  for (i in list_sub10) {
    n <- k_ring(i, radius = 1)
    n <- n[n != i]
    inter$i <- i
    inter$n <- n
    inter <- as.data.frame(inter)
    df <- rbind(inter, df)
    as.data.frame(df)
  }
  
  #retrieve from original data each n's attributes (topo_code, MSOA ID, activity)
  colnames(df) <- c("h3_10_char", "neighbours")
  i_df <- left_join(df, M)
  i_df <- i_df[c(1,2,4,6)]
  colnames(i_df) <- c("i", "h3_10_char", "topo_i", "activity_i")
  i_n_df <- left_join(i_df, M)
  i_n_df <- i_n_df[c(1,2,3,4,6,8)]
  colnames(i_n_df) <- c("i", "n", "topo_i", "activity_i", "topo_n", "activity_n")
  
  #NAs coerces as some n may be coming from outside the i's MSOA(crossboundary MSOA neighbours)
  i_n_df <- na.omit(i_n_df) # removes the neighbours which arent in the same region as their i
  
  #this detects creates a 1,0 binary column to note if each n's topo code is the same as i's topo_code with mutate()
  #then orders the dataset using arrange() to get in first position for each i the neighbour with topo code TRUE (1) and highest activity
  
  i_n_df <- i_n_df %>%
    mutate(same_topo = ifelse(i_n_df$topo_i == i_n_df$topo_n, 1, 0)) %>%
    arrange(i_n_df$i, -(i_n_df$same_topo), -(i_n_df$activity_n))
  
  #then remove duplicates and keep the first n emerging from the arrange(): that is the preferred neighbour. write it in the PNMx
  PNMx <- i_n_df[!duplicated(i_n_df$i),]
  PNMx <- PNMx[c(1,2)] # That is your Preferred Neighbour Matrix! (in dataframe format lol)
  
  ### using igraph package, get the components from PNMx ###
  PNGr <- graph_from_data_frame(PNMx, directed = FALSE, vertices = NULL)
  Groups <- components(PNGr)
  
  #write each group membership in dataframe
  group <- as.data.frame(Groups$membership)
  group <- rownames_to_column(group, "i")
  colnames(group) <- c("i", "group") ### That's all H310s which had to combine, and their attributed group
  group$group <- as.character(group$group)
  print(group)
  return(group)
}
