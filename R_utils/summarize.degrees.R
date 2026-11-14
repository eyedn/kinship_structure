# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# summarize.degrees.R
# ______________________________________________________________________________


summarize.degrees <- function(state, block.size) {
  n <- nrow(state$degree)
  counts <- numeric()
  unrelated <- 0
  # Bound temporary pair storage to the same row blocks as kinship summaries.
  for (start in seq.int(1L, n, by = block.size)) {
    rows <- seq.int(start, min(n, start + block.size - 1L))
    block <- state$degree[rows, , drop = FALSE]
    values <- block[outer(rows, seq_len(n), "<")]
    finite <- values[is.finite(values)]
    unrelated <- unrelated + sum(is.infinite(values))
    maximum <- max(c(length(counts), finite))
    counts <- c(counts, rep(0, maximum - length(counts))) +
      tabulate(finite, nbins = maximum)
  }
  generation <- max(state$individuals$generation)
  counts <- c(counts, unrelated)
  tibble::tibble(
    generation = generation, label = paste0("G", generation),
    degree = c(seq_len(length(counts) - 1L), Inf),
    count = counts, proportion = counts / (as.double(n) * (n - 1) / 2))
}
