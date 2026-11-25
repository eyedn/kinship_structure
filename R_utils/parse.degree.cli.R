# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# parse.degree.cli.R
# ______________________________________________________________________________


parse.degree.cli <- function(args = character(), defaults = list()) {
  allowed <- c("generations", "population-sizes", "seed", "output-dir")
  values <- defaults
  seen <- character()
  while (length(args)) {
    name <- sub("^--", "", args[1])
    if (!startsWith(args[1], "--") || !name %in% allowed ||
        name %in% seen || length(args) < 2L) {
      stop("Invalid or duplicate argument")
    }
    value <- args[2]
    if (name != "output-dir") {
      expression <- if (name == "population-sizes")
        "^[0-9]+(,[0-9]+)*$" else "^[0-9]+$"
      if (!grepl(expression, value)) stop("Invalid --", name)
      value <- as.numeric(strsplit(value, ",", fixed = TRUE)[[1]])
    }
    values[[gsub("-", ".", name, fixed = TRUE)]] <- value
    seen <- c(seen, name)
    args <- args[-c(1, 2)]
  }
  do.call(make.degree.config, values)
}
