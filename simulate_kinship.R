# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# simulate_kinship.R
# ______________________________________________________________________________


# Editable defaults
DEFAULT.GENERATIONS <- 100L
DEFAULT.POPULATION.SIZE <- 100L
DEFAULT.SEED <- 1L
DEFAULT.WORKERS <- 1L
DEFAULT.OUTPUT.DIR <- "outputs"
DEFAULT.FPS <- 5L
DEFAULT.BLOCK.SIZE <- 128L

# Locate helpers relative to this script for both source() and Rscript.
SCRIPT.FILE <- if (sys.nframe() > 0L) {
  tail(Filter(Negate(is.null),
              lapply(sys.frames(), `[[`, "ofile")), 1L)[[1]]
} else {
  sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
}
SCRIPT.DIR <- dirname(normalizePath(SCRIPT.FILE, mustWork = TRUE))
for (HELPER.FILE in list.files(file.path(SCRIPT.DIR, "R_utils"),
                                pattern = "\\.R$", full.names = TRUE)) {
  source(HELPER.FILE)
}

# Sourcing defines the interactive API without running or writing anything.
if (sys.nframe() == 0L) {
  tryCatch({
    CONFIG <- parse.cli(commandArgs(trailingOnly = TRUE))
    RESULT <- run.simulation(CONFIG)
    RUN.DIR <- write.results(RESULT)
    message("Saved simulation: ", RUN.DIR)
    render.figures(RESULT$histograms, RESULT$generations,
                   file.path(RUN.DIR, "figures"), CONFIG$workers, CONFIG$fps)
    message("Completed run: ", RUN.DIR)
  }, error = function(error) {
    message("Error: ", conditionMessage(error))
    quit(save = "no", status = 1L)
  })
}
