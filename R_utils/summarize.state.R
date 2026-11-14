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
  grouped.counts <- matrix(0, 100L, 6L)
  total <- 0
  zeros <- 0
  # Only materialize upper-triangle pairs for a bounded block of rows.
  for (start in seq.int(1L, n, by = block.size)) {
    rows <- seq.int(start, min(n, start + block.size - 1L))
    block <- k[rows, , drop = FALSE]
    values <- block[outer(rows, seq_len(n), "<")]
    bins <- findInterval(values, breaks, rightmost.closed = TRUE)
    counts <- counts + tabulate(bins, nbins = 100L)
    groups <- cohort.block.groups(state$individuals$generation, rows)
    grouped.counts <- grouped.counts + matrix(tabulate(
      bins + 100L * (groups - 1L), nbins = 600L), 100L, 6L)
    total <- total + sum(values)
    zeros <- zeros + sum(values == 0)
  }
  generation <- max(state$individuals$generation)
  cohorts <- table(state$individuals$generation)
  cohort.sizes <- paste0("G", names(cohorts), "=", as.integer(cohorts),
                         collapse = ", ")
  pairs <- as.double(n) * (n - 1) / 2
  degrees <- summarize.degrees(state, block.size, by.cohort = TRUE)
  histograms <- tibble::tibble(
    generation = generation, label = paste0("G", generation),
    bin = seq_len(100L), lower = head(breaks, -1L), upper = tail(breaks, -1L),
    right.closed = seq_len(100L) == 100L,
    count = counts, proportion = counts / pairs)
  grouped <- histograms[rep(seq_len(100L), 6L), ]
  grouped$count <- as.vector(grouped.counts)
  grouped$proportion <- grouped$count / pairs
  grouped$cohort.pair <- rep(cohort.pair.labels(), each = 100L)
  list(
    histograms.by.cohort = grouped,
    degree.histograms.by.cohort = degrees$by.cohort,
    generations = tibble::tibble(
      generation = generation, label = paste0("G", generation),
      cohort.sizes = cohort.sizes, active.size = n, pair.count = pairs,
      mean.kinship = total / pairs,
      mean.inbreeding = mean(state$individuals$inbreeding), zero.count = zeros),
    degree.histograms = degrees$aggregate,
    histograms = histograms)
}
