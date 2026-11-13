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
DEFAULT.OUTPUT.DIR <- "~/scratch/kinship_structure"
DEFAULT.FPS <- 5L
DEFAULT.BLOCK.SIZE <- 128L

# Locate helpers when sourcing, running selections, or using Rscript.
SCRIPT.CANDIDATES <- c(
  rev(unlist(lapply(sys.frames(), `[[`, "ofile"), use.names = FALSE)),
  sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)),
  "simulate_kinship.R")
SCRIPT.FILE <- SCRIPT.CANDIDATES[
  !is.na(SCRIPT.CANDIDATES) & file.exists(SCRIPT.CANDIDATES)][1]
SCRIPT.DIR <- dirname(normalizePath(SCRIPT.FILE, mustWork = TRUE))
for (HELPER.FILE in list.files(file.path(SCRIPT.DIR, "R_utils"),
                                pattern = "\\.R$", full.names = TRUE)) {
  source(HELPER.FILE)
}

# Run directly so objects and errors remain accessible in RStudio.
CONFIG <- parse.cli(commandArgs(trailingOnly = TRUE))
RESULT <- run.simulation(CONFIG)
RUN.DIR <- write.results(RESULT)
FIGURES.DIR <- file.path(RUN.DIR, "figures")
message("Run directory: ", RUN.DIR)
message("Figures directory: ", FIGURES.DIR)
RENDER.INFO <- render.figures(
  RESULT$histograms, RESULT$generations, FIGURES.DIR, fps = CONFIG$fps)
message("Animation: ", file.path(FIGURES.DIR, "kinship_histogram.gif"))
message("Completed run: ", RUN.DIR)
