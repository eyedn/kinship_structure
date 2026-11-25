# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# run.degree.batch.R
# ______________________________________________________________________________


run.degree.batch <- function(config = make.degree.config(), render = TRUE) {
  config <- do.call(make.degree.config, config)
  root <- path.expand(config$output.dir)
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(root)) stop("Cannot create output directory: ", root)
  repeat {
    batch <- tempfile(paste0("degrees_", format(Sys.time(), "%Y%m%d_%H%M%S"),
                             "_"), tmpdir = root)
    if (dir.create(batch, showWarnings = FALSE)) break
    stop("Cannot create unique batch directory under ", root)
  }
  batch <- normalizePath(batch)
  saveRDS(config, file.path(batch, "configuration.rds"))
  message("Batch directory: ", batch)
  for (population.size in config$population.sizes) {
    result <- run.degree.simulation(config, population.size)
    output <- file.path(batch, paste0("N_", population.size))
    write.degree.results(result, output)
    message("Numerical outputs saved: ", output)
    if (render) render.degree.figures(result, file.path(output, "figures"))
    rm(result)
    invisible(gc())
  }
  message("Completed batch: ", batch)
  invisible(batch)
}
