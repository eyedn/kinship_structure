# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# simulated_kinship_degrees.R
# ______________________________________________________________________________


# Editable defaults: each size is an independent constant-size population.
DEFAULT.DEGREE.GENERATIONS <- 100L
DEFAULT.DEGREE.POPULATION.SIZES <- c(100L, 1000L, 10000L, 100000L)
DEFAULT.DEGREE.SEED <- 1L
DEFAULT.DEGREE.OUTPUT.DIR <- "~/scratch/kinship_structure"
DEFAULT.DEGREE.FPS <- 25L
DEFAULT.DEGREE.BLOCK.SIZE <- 512L

# Locate helpers both when sourced and when called with Rscript.
SCRIPT.CANDIDATES <- c(
  rev(unlist(lapply(sys.frames(), `[[`, "ofile"), use.names = FALSE)),
  sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)),
  "simulated_kinship_degrees.R")
SCRIPT.FILE <- SCRIPT.CANDIDATES[
  !is.na(SCRIPT.CANDIDATES) & file.exists(SCRIPT.CANDIDATES)][1]
SCRIPT.DIR <- dirname(normalizePath(SCRIPT.FILE, mustWork = TRUE))
for (HELPER.FILE in list.files(file.path(SCRIPT.DIR, "R_utils"),
                                pattern = "\\.R$", full.names = TRUE)) {
  source(HELPER.FILE)
}
CONFIG <- parse.degree.cli(commandArgs(trailingOnly = TRUE), list(
  generations = DEFAULT.DEGREE.GENERATIONS,
  population.sizes = DEFAULT.DEGREE.POPULATION.SIZES,
  seed = DEFAULT.DEGREE.SEED, output.dir = DEFAULT.DEGREE.OUTPUT.DIR,
  fps = DEFAULT.DEGREE.FPS, block.size = DEFAULT.DEGREE.BLOCK.SIZE))
BATCH.DIR <- run.degree.batch(CONFIG)
