# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# animation.generations.R
# ______________________________________________________________________________


animation.generations <- function(generations) {
  as.integer(unique(c(seq(0, generations - 1L, by = 5L), generations - 1L)))
}
