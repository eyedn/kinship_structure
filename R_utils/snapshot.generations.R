# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# snapshot.generations.R
# ______________________________________________________________________________


snapshot.generations <- function(generations) {
  candidates <- unique(c(0:5, floor(generations / 2), generations - 1L))
  as.integer(candidates[candidates >= 0 & candidates < generations])
}
