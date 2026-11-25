# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# summarize.degree.state.R
# ______________________________________________________________________________


summarize.degree.state <- function(state, metric = "steps") {
  counts <- numeric(256L)
  # Each tabulation is bounded by a tile; double totals exceed 2^31 safely.
  for (key in ls(state$tiles, all.names = TRUE)) {
    values <- get(key, envir = state$tiles, inherits = FALSE)[[metric]]
    counts <- accumulate.degree.counts(counts, values)
  }
  if (counts[1] != 0) stop("Self-values found in distinct pair storage")
  total <- choose(as.double(nrow(state$individuals)), 2)
  if (sum(counts) != total) stop("Pair count mismatch")
  generation <- max(state$individuals$generation)
  data.frame(generation = generation, label = paste0("G", generation),
             degree = c(1:254, Inf), count = counts[-1],
             proportion = counts[-1] / total)
}
