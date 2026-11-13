# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# sample.parents.R
# ______________________________________________________________________________


sample.parents <- function(previous.ids, population.size) {
  # Offset sampling gives each ordered distinct-parent pair equal probability.
  n <- length(previous.ids)
  p <- sample.int(n, population.size, replace = TRUE)
  q <- sample.int(n - 1L, population.size, replace = TRUE)
  q <- q + (q >= p)
  cbind(previous.ids[p], previous.ids[q])
}
