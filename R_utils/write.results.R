# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# write.results.R
# ______________________________________________________________________________


write.results <- function(result) {
  root <- path.expand(result$config$output.dir)
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  # Atomic directory creation prevents concurrent runs sharing a directory.
  repeat {
    run.dir <- tempfile(pattern = paste0("run_", format(Sys.time(),
                           "%Y%m%d_%H%M%S"), "_"), tmpdir = root)
    if (dir.create(run.dir, showWarnings = FALSE)) break
    if (!dir.exists(root) || file.access(root, 2L) != 0L) {
      stop("Cannot create a run directory under: ", root)
    }
  }
  saveRDS(result$config, file.path(run.dir, "configuration.rds"))
  dput(result$config, file = file.path(run.dir, "configuration.R"))
  writeLines(as.character(result$config$seed), file.path(run.dir, "seed.txt"))
  write.csv(result$generations, file.path(run.dir, "generations.csv"),
            row.names = FALSE)
  write.csv(result$histograms, file.path(run.dir, "histograms.csv"),
            row.names = FALSE)
  saveRDS(result$final.state, file.path(run.dir, "final_state.rds"))
  packages <- c("tibble", "dplyr", "ggplot2", "future", "furrr",
                "gganimate", "magick", "testthat")
  versions <- vapply(packages, function(package) {
    if (requireNamespace(package, quietly = TRUE)) {
      as.character(utils::packageVersion(package))
    } else "not installed"
  }, character(1))
  write.csv(data.frame(package = packages, version = versions),
            file.path(run.dir, "package_versions.csv"), row.names = FALSE)
  writeLines(c("Simulation RNG: Mersenne-Twister / Inversion / Rejection", "",
               capture.output(utils::sessionInfo())),
             file.path(run.dir, "session_info.txt"))
  normalizePath(run.dir)
}
