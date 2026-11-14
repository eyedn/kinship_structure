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
  as.integer(unique(round(seq(0, generations - 1L,
                              length.out = min(6L, generations)))))
}
