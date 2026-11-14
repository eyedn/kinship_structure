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


animation.generations <- function(generations, step = 3L) {
  if (!is.numeric(step) || length(step) != 1L || is.na(step) ||
      !is.finite(step) || step < 1 || step != floor(step) ||
      step > .Machine$integer.max) {
    stop("gif.generation.step must be a positive integer.")
  }
  as.integer(unique(c(seq(0, generations - 1L, by = step), generations - 1L)))
}
