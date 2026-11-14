# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# summarize.state.R
# ______________________________________________________________________________


summarize.state <- function(state, block.size = DEFAULT.BLOCK.SIZE) {
  k <- state$kinship
  n <- nrow(k)
  breaks <- seq(0, 1, length.out = 101L)
  counts <- numeric(100)
  total <- 0
  zeros <- 0
  # Only materialize upper-triangle pairs for a bounded block of rows.
  for (start in seq.int(1L, n, by = block.size)) {
    rows <- seq.int(start, min(n, start + block.size - 1L))
    block <- k[rows, , drop = FALSE]
    values <- block[outer(rows, seq_len(n), "<")]
    counts <- counts + tabulate(
      findInterval(values, breaks, rightmost.closed = TRUE), nbins = 100L)
    total <- total + sum(values)
    zeros <- zeros + sum(values == 0)
  }
  generation <- max(state$individuals$generation)
  cohorts <- table(state$individuals$generation)
  cohort.sizes <- paste0("G", names(cohorts), "=", as.integer(cohorts),
                         collapse = ", ")
  pairs <- as.double(n) * (n - 1) / 2
  list(
    generations = tibble::tibble(
      generation = generation, label = paste0("G", generation),
      cohort.sizes = cohort.sizes, active.size = n, pair.count = pairs,
      mean.kinship = total / pairs,
      mean.inbreeding = mean(state$individuals$inbreeding), zero.count = zeros),
    degree.histograms = summarize.degrees(state, block.size),
    histograms = tibble::tibble(
      generation = generation, label = paste0("G", generation),
      bin = seq_len(100L), lower = head(breaks, -1L), upper = tail(breaks, -1L),
      right.closed = seq_len(100L) == 100L,
      count = counts, proportion = counts / pairs))
}
