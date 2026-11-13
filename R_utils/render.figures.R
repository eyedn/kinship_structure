# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# render.figures.R
# ______________________________________________________________________________


render.figures <- function(histograms, generations, output.dir,
                           fps = DEFAULT.FPS) {
  if (!is.numeric(fps) || length(fps) != 1L || is.na(fps) ||
      !is.finite(fps) || fps < 1 || fps != floor(fps) ||
      fps > .Machine$integer.max) {
    stop("fps must be a positive integer.")
  }
  packages <- c("ggplot2", "gganimate", "gifski", "future", "furrr")
  for (package in packages) {
    if (!requireNamespace(package, quietly = TRUE)) {
      stop("Install required rendering package: ", package)
    }
  }
  output.dir <- path.expand(output.dir)
  dir.create(output.dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(output.dir)) {
    stop("Cannot create figures directory: ", output.dir)
  }
  selected <- snapshot.generations(nrow(generations))
  jobs <- lapply(selected, function(generation) {
    list(path = file.path(output.dir,
                          paste0("histogram_G", generation, ".png")),
         plot = plot.histograms(histograms, generations, generation),
         width = 8, height = 4.8)
  })
  jobs <- c(jobs, list(
    list(path = file.path(output.dir, "histograms_faceted.png"),
         plot = plot.histograms(histograms, generations, selected, TRUE),
         width = 12, height = max(4, 2.8 * ceiling(length(selected) / 2))),
    list(path = file.path(output.dir, "kinship_heatmap.png"),
         plot = plot.heatmap(histograms), width = 8, height = 6)))
  old.plan <- future::plan()
  on.exit(future::plan(old.plan), add = TRUE)
  available.cores <- future::availableCores()
  actual.workers <- min(available.cores, length(jobs))
  message(sprintf("Detected %d available CPUs; using %d plotting workers.",
                  available.cores, actual.workers))
  if (actual.workers > 1L) {
    future::plan(future::multisession, workers = actual.workers)
    furrr::future_walk(jobs, save.static.plot,
                        .options = furrr::furrr_options(seed = TRUE))
  } else {
    future::plan(future::sequential)
    lapply(jobs, save.static.plot)
  }
  animation <- plot.histograms(histograms, generations) +
    gganimate::transition_manual(frame.label) +
    ggplot2::labs(title = "{current_frame}")
  gganimate::animate(
    animation, nframes = nrow(generations), fps = fps,
    width = 960, height = 600, device = "png", res = 120,
    renderer = gganimate::gifski_renderer(
      file.path(output.dir, "kinship_histogram.gif"), loop = TRUE))
  invisible(list(workers = actual.workers, snapshots = selected))
}
