# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# write.degree.results.R
# ______________________________________________________________________________


write.degree.results <- function(result, output.dir) {
  dir.create(output.dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(result$config, file.path(output.dir, "configuration.rds"))
  dput(result$config, file = file.path(output.dir, "configuration.R"))
  writeLines(as.character(result$config$seed),
             file.path(output.dir, "seed.txt"))
  tables <- list(parents = result$parents, generations = result$generations,
                 steps_histograms = result$steps,
                 relationship_histograms = result$relationship)
  for (name in names(tables)) {
    utils::write.csv(tables[[name]], file.path(output.dir,
                      paste0(name, ".csv")), row.names = FALSE)
  }
  # Uncompressed serialization avoids a second compressed copy of the pair data.
  saveRDS(result$final.state, file.path(output.dir, "final_state.rds"),
           compress = FALSE)
  writeLines(c("Simulation RNG: Mersenne-Twister / Inversion / Rejection",
               capture.output(utils::sessionInfo())),
             file.path(output.dir, "session_info.txt"))
  invisible(output.dir)
}
