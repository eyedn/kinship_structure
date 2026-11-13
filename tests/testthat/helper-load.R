# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# helper-load.R
# ______________________________________________________________________________

# Load defaults and helpers without executing the entry-point workflow.
SCRIPT.DIR <- normalizePath(file.path("..", ".."))
SCRIPT.EXPRESSIONS <- parse(file.path(SCRIPT.DIR, "simulate_kinship.R"))
for (EXPRESSION in SCRIPT.EXPRESSIONS) {
  if (is.call(EXPRESSION) && identical(EXPRESSION[[1]], as.name("<-")) &&
      startsWith(as.character(EXPRESSION[[2]]), "DEFAULT.")) {
    eval(EXPRESSION, envir = .GlobalEnv)
  }
}
for (HELPER.FILE in list.files(file.path(SCRIPT.DIR, "R_utils"),
                                pattern = "\\.R$", full.names = TRUE)) {
  source(HELPER.FILE)
}
