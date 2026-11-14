# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# theme.manuscript.R
# ______________________________________________________________________________


theme.manuscript <- function() {
  ggplot2::theme_bw(base_size = 24) +
    ggplot2::theme(
      strip.text = ggplot2::element_text(face = "plain"),
      strip.background = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.spacing = grid::unit(1.5, "lines"),
      panel.spacing.x = grid::unit(2.5, "lines"),
      plot.margin = ggplot2::margin(t = 16, r = 24, b = 16, l = 32),
      legend.position = "top", legend.direction = "horizontal",
      plot.title = ggplot2::element_text(size = 24),
      plot.caption = ggplot2::element_text(size = 16))
}
