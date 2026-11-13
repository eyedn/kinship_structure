# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# save.static.plot.R
# ______________________________________________________________________________


save.static.plot <- function(job) {
  ggplot2::ggsave(job$path, plot = job$plot, width = job$width,
                  height = job$height, dpi = 150, bg = "white")
  invisible(job$path)
}
