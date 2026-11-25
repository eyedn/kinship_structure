# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# plot.degree.histograms.R
# ______________________________________________________________________________


plot.degree.histograms <- function(histograms, generations,
                                   selected = generations$generation,
                                   faceted = FALSE, metric = "steps") {
  data <- histograms
  categories <- unique(data$degree)
  data$category <- factor(data$degree, levels = categories,
                          labels = ifelse(is.infinite(categories),
                                          "Unrelated", categories))
  labels <- paste0(generations$label, " (", generations$cohort.sizes, ")")
  data$frame.label <- factor(labels[match(data$generation,
                                         generations$generation)],
                             levels = labels, ordered = TRUE)
  data$percentage <- 100 * data$proportion
  maximum <- max(1, max(data$percentage) * 1.05)
  data <- data[data$generation %in% selected, ]
  data$frame.label <- droplevels(data$frame.label)
  plot <- ggplot2::ggplot(data, ggplot2::aes(category, percentage)) +
    ggplot2::geom_col(width = 0.9, fill = "grey60") +
    ggplot2::geom_point(data = data[data$count == 0, ],
                        ggplot2::aes(y = 0), shape = 3, size = 1.2) +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::scale_y_continuous(
      trans = scales::log1p_trans(), limits = c(0, maximum),
      breaks = c(0, 5, 10, 15, 20, 25, 50, 75, 100),
      expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::labs(x = if (metric == "steps") "Pedigree steps" else
                    "Closest-relationship degree",
                  y = "Percentage of active pairs\n(log1p scale)",
                  caption = "+ marks zero-count categories") +
    theme.manuscript()
  if (faceted) {
    plot <- plot + ggplot2::facet_wrap(~frame.label, ncol = 2,
      labeller = ggplot2::label_wrap_gen(width = 35))
  } else if (length(selected) == 1L) {
    plot <- plot + ggplot2::labs(title = paste(strwrap(
      as.character(data$frame.label[1]), width = 55), collapse = "\n"))
  }
  plot
}
