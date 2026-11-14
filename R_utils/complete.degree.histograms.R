# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# complete.degree.histograms.R
# ______________________________________________________________________________


complete.degree.histograms <- function(histograms) {
  finite <- histograms$degree[is.finite(histograms$degree)]
  categories <- c(seq_len(max(c(0, finite))), Inf)
  generations <- unique(histograms$generation)
  data <- tibble::tibble(
    generation = rep(generations, each = length(categories)),
    degree = rep(categories, times = length(generations)))
  keys <- c("generation", "degree")
  if ("cohort.pair" %in% names(histograms)) {
    data <- data[rep(seq_len(nrow(data)), 6L), ]
    data$cohort.pair <- rep(cohort.pair.labels(), each = nrow(data) / 6L)
    keys <- c(keys, "cohort.pair")
  }
  data <- dplyr::left_join(data, histograms, by = keys)
  data$label <- paste0("G", data$generation)
  data$count[is.na(data$count)] <- 0
  data$proportion[is.na(data$proportion)] <- 0
  columns <- c("generation", "label", "degree", "count", "proportion")
  if ("cohort.pair" %in% names(data)) columns <- c(columns, "cohort.pair")
  data[, columns]
}
