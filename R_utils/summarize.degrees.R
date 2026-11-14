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


summarize.degrees <- function(state, block.size, by.cohort = FALSE) {
  n <- nrow(state$degree)
  counts <- numeric()
  unrelated <- 0
  grouped.counts <- matrix(0, 0L, 6L)
  grouped.unrelated <- numeric(6L)
  # Bound temporary pair storage to the same row blocks as kinship summaries.
  for (start in seq.int(1L, n, by = block.size)) {
    rows <- seq.int(start, min(n, start + block.size - 1L))
    block <- state$degree[rows, , drop = FALSE]
    values <- block[outer(rows, seq_len(n), "<")]
    finite <- values[is.finite(values)]
    unrelated <- unrelated + sum(is.infinite(values))
    maximum <- max(c(length(counts), finite))
    groups <- cohort.block.groups(state$individuals$generation, rows)
    grouped.unrelated <- grouped.unrelated +
      tabulate(groups[is.infinite(values)], nbins = 6L)
    grouped.counts <- rbind(grouped.counts,
      matrix(0, maximum - nrow(grouped.counts), 6L))
    if (maximum > 0) {
      grouped.counts <- grouped.counts + matrix(tabulate(
        values[is.finite(values)] +
          maximum * (groups[is.finite(values)] - 1L),
        nbins = maximum * 6L), maximum, 6L)
    }
    counts <- c(counts, rep(0, maximum - length(counts))) +
      tabulate(finite, nbins = maximum)
  }
  generation <- max(state$individuals$generation)
  counts <- c(counts, unrelated)
  aggregate <- tibble::tibble(
    generation = generation, label = paste0("G", generation),
    degree = c(seq_len(length(counts) - 1L), Inf),
    count = counts, proportion = counts / (as.double(n) * (n - 1) / 2))
  if (!by.cohort) return(aggregate)
  grouped <- aggregate[rep(seq_len(nrow(aggregate)), 6L), ]
  grouped$count <- as.vector(rbind(grouped.counts, grouped.unrelated))
  grouped$proportion <- grouped$count / (as.double(n) * (n - 1) / 2)
  grouped$cohort.pair <- rep(cohort.pair.labels(), each = nrow(aggregate))
  list(aggregate = aggregate, by.cohort = grouped)
}
