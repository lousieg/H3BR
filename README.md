# H3BR
Data-driven regionalisation algorithm built from h3 indexing (h3 R bindings found here: https://github.com/crazycapivara/h3-r)

Paper detailing the methodology, published in Geographical Analysis: https://doi.org/10.1111/gean.12406

The current version of the algorithm is exploratory and was developed in the context of my UCL PhD research in Geography titled "Tessellating the Space-Time Prism: Regionalisation of In-app Location Data for Privacy Protection and Data Preservation"

 The algorithm takes data points aggregated to H3 indexes of resolution 10 (H310) and iteratively combines hexagons with neighbours until a defined threshold is reached. Considers merging factors, such as unerlying terrain or other attributes provided with the H310 units.
