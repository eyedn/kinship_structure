# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# plot.heatmap.R
# ______________________________________________________________________________


plot.heatmap <- function(histograms) {
  degree.metric <- "degree" %in% names(histograms)
  if (degree.metric) {
    histograms <- complete.degree.histograms(histograms)
    categories <- unique(histograms$degree)
    labels <- ifelse(is.infinite(categories), "Unrelated", categories)
    histograms$category <- factor(histograms$degree,
                                   levels = categories, labels = labels)
  }
  plot <- if (degree.metric) {
    ggplot2::ggplot(histograms, ggplot2::aes(
      x = category, y = generation, fill = proportion))
  } else {
    ggplot2::ggplot(histograms, ggplot2::aes(
      x = (lower + upper) / 2, y = generation, fill = proportion))
  }
  plot <- plot +
    ggplot2::geom_tile(width = if (degree.metric) 1 else 0.01, height = 1) +
    ggplot2::scale_fill_viridis_c(
      name = "Proportion of active pairs", trans = "identity",
      limits = c(0, max(histograms$proportion)),
      guide = ggplot2::guide_colourbar(
        direction = "horizontal", title.position = "top",
        barwidth = grid::unit(10, "cm"), barheight = grid::unit(0.5, "cm"))) +
    ggplot2::scale_y_continuous(
      breaks = unique(round(pretty(histograms$generation))),
      labels = function(x) paste0("G", x),
      expand = ggplot2::expansion(mult = 0)) +
    ggplot2::labs(
      x = if (degree.metric) "Pedigree distance (parent–child steps)" else
        "Pedigree kinship", y = "Generation",
      title = if (degree.metric) {
        "Pedigree distances across the active population"
      } else "Kinship across the rolling active population") +
    theme.manuscript() +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
  if (degree.metric) {
    plot <- plot + ggplot2::scale_x_discrete(drop = FALSE)
  } else {
    plot <- plot + ggplot2::scale_x_continuous(
      limits = c(0, 1), expand = ggplot2::expansion(mult = 0))
  }
  plot
}
