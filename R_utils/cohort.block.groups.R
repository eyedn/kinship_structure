# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# cohort.block.groups.R
# ______________________________________________________________________________


cohort.block.groups <- function(generations, rows) {
  offsets <- max(generations) - generations
  # Column-major order matches the upper-triangle extraction in each block.
  keys <- outer(offsets[rows], 3L * offsets, "+") + 1L
  lookup <- c(1L, 4L, 5L, 4L, 2L, 6L, 5L, 6L, 3L)
  lookup[keys[outer(rows, seq_along(generations), "<")]]
}
