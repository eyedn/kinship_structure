# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# render.degree.figures.R
# ______________________________________________________________________________


render.degree.figures <- function(result, output.dir, width = 1400L,
                                  height = 800L) {
  for (package in c("ggplot2", "magick", "scales")) {
    if (!requireNamespace(package, quietly = TRUE)) stop("Install ", package)
  }
  dir.create(output.dir, recursive = TRUE, showWarnings = FALSE)
  frames <- seq.int(0L, result$config$generations - 1L)
  early <- head(frames, 10L)
  snapshots <- unique(c(seq.int(0L, max(frames), by = 10L), max(frames)))
  temporary <- tempfile("degree_frames_")
  dir.create(temporary)
  on.exit(unlink(temporary, recursive = TRUE), add = TRUE)
  # Rendering stays sequential so a large final pair store is never exported.
  for (metric in c("steps", "relationship")) {
    for (selection in c("first10", "snapshots")) {
      selected <- if (selection == "first10") early else snapshots
      plot <- plot.degree.histograms(result[[metric]], result$generations,
                                      selected, TRUE, metric)
      ggplot2::ggsave(file.path(output.dir, paste0(metric, "_", selection,
                                                  "_faceted.png")), plot,
                     width = 22, height = max(8, 5.5 * ceiling(
                       length(selected) / 2)), units = "in", dpi = 150,
                     limitsize = FALSE, bg = "white")
    }
    images <- vector("list", length(frames))
    for (k in seq_along(frames)) {
      path <- file.path(temporary, paste0("frame_", k, ".png"))
      plot <- plot.degree.histograms(result[[metric]], result$generations,
                                      frames[k], FALSE, metric)
      ggplot2::ggsave(path, plot, width = width / 100, height = height / 100,
                     units = "in", dpi = 100, bg = "white")
      images[[k]] <- magick::image_read(path)
      unlink(path)
    }
    animation <- magick::image_animate(magick::image_join(images),
                                        fps = result$config$fps, loop = 0,
                                        optimize = FALSE)
    magick::image_write(animation, file.path(output.dir,
                         paste0(metric, "_histogram.gif")), format = "gif")
    rm(images, animation)
  }
  invisible(list(early = early, snapshots = snapshots, frames = frames))
}
