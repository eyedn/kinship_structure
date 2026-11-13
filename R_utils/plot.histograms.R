# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# plot.histograms.R
# ______________________________________________________________________________


plot.histograms <- function(histograms, generations, selected = NULL,
                            faceted = FALSE) {
  generations <- generations[order(generations$generation), ]
  generations$frame.label <- paste0(generations$label, " (",
                                     generations$cohort.sizes, ")")
  data <- dplyr::left_join(histograms,
                           generations[, c("generation", "frame.label")],
                           by = "generation")
  data$frame.label <- factor(data$frame.label,
                             levels = generations$frame.label, ordered = TRUE)
  data$percentage <- 100 * data$proportion
  y.maximum <- max(1, 100 * max(histograms$proportion) * 1.05)
  if (!is.null(selected)) data <- data[data$generation %in% selected, ]
  plot <- ggplot2::ggplot(
    data, ggplot2::aes(x = (lower + upper) / 2, y = percentage)) +
    ggplot2::geom_col(width = 0.01, fill = "#247c91") +
    ggplot2::geom_point(data = data[data$count == 0, ],
                        shape = 3, size = 0.6, alpha = 0.5) +
    ggplot2::scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2),
                                expand = ggplot2::expansion(mult = 0)) +
    # Log1p transforms percentages while preserving exact zeros.
    ggplot2::scale_y_continuous(
      trans = scales::log1p_trans(),
      breaks = c(0, 25, 50, 75, 100),
      labels = c("0", "25", "50", "75", "100"),
      limits = c(0, y.maximum),
      expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::labs(x = "Pedigree kinship",
                  y = "Percentage of active pairs (log1p scale)",
                  caption = "100 bins of width 0.01; + marks zero-count bins") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                    panel.spacing.x = grid::unit(1.5, "lines"))
  if (faceted) {
    plot <- plot + ggplot2::facet_wrap(~frame.label, ncol = 2)
  } else if (length(unique(data$generation)) == 1L) {
    plot <- plot + ggplot2::labs(title = as.character(data$frame.label[1]))
  }
  plot
}
