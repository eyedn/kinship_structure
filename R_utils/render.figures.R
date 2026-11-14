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
                           fps = DEFAULT.FPS, degree.histograms = NULL,
                           gif.generation.step = 3L,
                           histograms.by.cohort = NULL,
                           degree.histograms.by.cohort = NULL) {
  if (!is.numeric(fps) || length(fps) != 1L || is.na(fps) ||
      !is.finite(fps) || fps < 1 || fps != floor(fps) ||
      fps > .Machine$integer.max) {
    stop("fps must be a positive integer.")
  }
  packages <- c("ggplot2", "gganimate", "magick", "future", "furrr")
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
  early.selected <- seq.int(0L, min(9L, nrow(generations) - 1L))
  animated.selected <- animation.generations(nrow(generations),
                                                gif.generation.step)
  metrics <- list(kinship = histograms)
  if (!is.null(degree.histograms)) {
    metrics$degree <- complete.degree.histograms(degree.histograms)
  }
  if (!is.null(histograms.by.cohort)) {
    metrics$kinship_by_cohort <- histograms.by.cohort
  }
  if (!is.null(degree.histograms.by.cohort)) {
    metrics$degree_by_cohort <- complete.degree.histograms(
      degree.histograms.by.cohort)
  }
  jobs <- unlist(lapply(names(metrics), function(metric) {
    data <- metrics[[metric]]
    prefix <- if (startsWith(metric, "degree")) "degree_" else ""
    grouped <- grepl("by_cohort", metric, fixed = TRUE)
    stem <- paste0(prefix, "histograms", if (grouped) "_by_cohort" else "")
    plots <- list(
      list(path = file.path(output.dir,
                            paste0(stem, "_faceted.png")),
           plot = plot.histograms(data, generations, selected, TRUE),
           width = 22, height = max(8, 5.5 * ceiling(length(selected) / 2))),
      list(path = file.path(output.dir,
                            paste0(stem, "_first10_faceted.png")),
           plot = plot.histograms(data, generations, early.selected, TRUE),
           width = 22,
           height = max(8, 5.5 * ceiling(length(early.selected) / 2))))
    if (!grouped) {
      plots <- c(plots, list(list(
        path = file.path(output.dir, paste0(metric, "_heatmap.png")),
        plot = plot.heatmap(data), width = 16, height = 10)))
    }
    plots
  }), recursive = FALSE)
  old.plan <- future::plan()
  on.exit(future::plan(old.plan), add = TRUE)
  core.counts <- future::availableCores(which = "all")
  available.cores <- resolve.available.cores(core.counts)
  message("CPU detection: ", paste(names(core.counts), core.counts,
                                    sep = "=", collapse = ", "))
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
  for (metric in names(metrics)) {
    animation <- plot.histograms(metrics[[metric]], generations,
                                   animated.selected) +
      gganimate::transition_manual(frame.label) +
      ggplot2::labs(title = "{current_frame}")
    animation <- gganimate::animate(
      animation, nframes = length(animated.selected), fps = fps,
      width = 1400, height = 800, device = "png", res = 100,
      renderer = gganimate::magick_renderer(loop = TRUE))
    suffix <- if (grepl("by_cohort", metric, fixed = TRUE))
      "_by_cohort" else ""
    name <- paste0(sub("_by_cohort", "", metric, fixed = TRUE),
                    "_histogram", suffix, ".gif")
    magick::image_write(animation, path = file.path(output.dir, name),
                         format = "gif")
  }
  invisible(list(available.cores = available.cores, core.counts = core.counts,
                 workers = actual.workers, snapshots = selected,
                 early.snapshots = early.selected,
                 animation.generations = animated.selected))
}
