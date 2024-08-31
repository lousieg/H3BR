# H3BR
Data-driven regionalisation algorithm built from h3 indexing (h3 R bindings found here: https://github.com/crazycapivara/h3-r)

Paper detailing the methodology, published in Geographical Analysis: https://doi.org/10.1111/gean.12406

The current version of the algorithm is exploratory and was developed in the context of my UCL PhD research in Geography titled "Tessellating the Space-Time Prism: Regionalisation of In-app Location Data for Privacy Protection and Data Preservation"

 The algorithm takes data points aggregated to H3 indexes of resolution 10 (H310) and iteratively combines hexagons with neighbours until a defined threshold is reached. Considers merging factors, such as unerlying terrain or other attributes provided with the H310 units.

## Dependencies

The following R packages are required to run this project:

- `tidtverse`, `tibble` and `data.table`: for rapid data manipulation
- `h3`: for rapid indexing of space using h3, the atomic unit base for the regionalisation process
- `igraph`: for graph-related operations
- `sf`: for spatial operations (final merge of polygons)
You can install these packages using the following commands:

```r
install.packages("tidyverse")
install.packages("tibble")
install.packages("data.table")
remotes::install_github("crazycapivara/h3-r")
install.packages("igraph")
install.packages("sf")
```
## Source files and description of algorithm
functions in the R/ folder support the main.R script containing the algorithm. 
The Core_H3BR_function.R source file loads in the main function, which takes a dataframe containing H310 indexes with attributes and activity, and returns a Preferred Neighbour Matrix (PNMx) containing the H310 with a group membership corresponding to the neighbours it should merge with to create a region meeting threshold. So far, the threshold is set to 10 in main.R but future updates will allow for threshold selection when running the functions.
The iteration_functions.R source file contains all the functions necessary to the iterative process: if some groups remain under the threshold, the process loops and disbands these groups to reattribute their H310s into neighbourhing groups above threshold. 

