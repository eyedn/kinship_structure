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
  degree.metric <- "degree" %in% names(histograms)
  if (degree.metric) histograms <- complete.degree.histograms(histograms)
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
  if (degree.metric) {
    categories <- unique(histograms$degree)
    labels <- ifelse(is.infinite(categories), "Unrelated", categories)
    data$category <- factor(data$degree, levels = categories, labels = labels)
  }
  if (!is.null(selected)) data <- data[data$generation %in% selected, ]
  plot <- if (degree.metric) {
    ggplot2::ggplot(data, ggplot2::aes(x = category, y = percentage))
  } else {
    ggplot2::ggplot(data, ggplot2::aes(x = (lower + upper) / 2, y = percentage))
  }
  plot <- plot +
    ggplot2::geom_col(width = if (degree.metric) 0.9 else 0.01,
                      fill = "#247c91") +
    # gganimate cannot build a discrete layer with no rows.
    (if (any(data$count == 0)) {
      ggplot2::geom_point(data = data[data$count == 0, ],
                          shape = 3, size = 1.2, alpha = 0.5)
    }) +
    # Log1p transforms percentages while preserving exact zeros.
    ggplot2::scale_y_continuous(
      trans = scales::log1p_trans(),
      breaks = c(0, 25, 50, 75, 100),
      labels = c("0", "25", "50", "75", "100"),
      limits = c(0, y.maximum),
      expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::labs(
      x = if (degree.metric) "Pedigree distance (parent–child steps)" else
        "Pedigree kinship",
      y = "Percentage of active pairs\n(log1p scale)",
      caption = if (degree.metric) "+ marks zero-count categories" else
        "100 bins of width 0.01; + marks zero-count bins") +
    theme.manuscript()
  if (degree.metric) {
    plot <- plot + ggplot2::scale_x_discrete(drop = FALSE)
  } else {
    plot <- plot + ggplot2::scale_x_continuous(
      limits = c(0, 1), breaks = seq(0, 1, 0.2),
      expand = ggplot2::expansion(mult = 0))
  }
  if (faceted) {
    plot <- plot + ggplot2::facet_wrap(
      ~frame.label, ncol = 2,
      labeller = ggplot2::label_wrap_gen(width = 35))
  } else if (length(unique(data$generation)) == 1L) {
    plot <- plot + ggplot2::labs(
      title = paste(strwrap(as.character(data$frame.label[1]), width = 55),
                    collapse = "\n"))
  }
  plot
}
