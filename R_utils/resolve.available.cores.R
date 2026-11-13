# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# resolve.available.cores.R
# ______________________________________________________________________________


resolve.available.cores <- function(core.counts) {
  valid <- core.counts[is.finite(core.counts) & core.counts >= 1]
  if (length(valid) == 0L) return(1L)
  as.integer(min(valid))
}
