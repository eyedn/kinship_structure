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
  ggplot2::ggplot(histograms,
                  ggplot2::aes(x = (lower + upper) / 2, y = generation,
                               fill = proportion)) +
    ggplot2::geom_tile(width = 0.01, height = 1) +
    ggplot2::scale_fill_viridis_c(
      name = "Proportion\nof active pairs", trans = "identity",
      limits = c(0, max(histograms$proportion))) +
    ggplot2::scale_x_continuous(limits = c(0, 1),
                                expand = ggplot2::expansion(mult = 0)) +
    ggplot2::scale_y_continuous(
      breaks = unique(round(pretty(histograms$generation))),
      labels = function(x) paste0("G", x),
      expand = ggplot2::expansion(mult = 0)) +
    ggplot2::labs(x = "Pedigree kinship", y = "Generation",
                  title = "Kinship across the rolling active population") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
}
