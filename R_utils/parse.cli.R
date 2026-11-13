# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# parse.cli.R
# ______________________________________________________________________________


parse.cli <- function(args) {
  allowed <- c("generations", "population-sizes", "seed", "output-dir")
  values <- list()
  i <- 1L
  while (i <= length(args)) {
    token <- args[i]
    if (!startsWith(token, "--")) stop("Expected a named --argument.")
    token <- substring(token, 3L)
    equals <- regexpr("=", token, fixed = TRUE)[1]
    if (equals > 0L) {
      name <- substr(token, 1L, equals - 1L)
      value <- substring(token, equals + 1L)
    } else {
      name <- token
      i <- i + 1L
      if (i > length(args) || startsWith(args[i], "--")) {
        stop("Missing value for --", name, call. = FALSE)
      }
      value <- args[i]
    }
    if (!name %in% allowed) stop("Unknown argument: --", name, call. = FALSE)
    if (name %in% names(values)) stop("Duplicate argument: --", name)
    if (name == "output-dir") {
      values[[name]] <- value
    } else {
      expression <- if (name == "population-sizes") {
        "^[0-9]+(,[0-9]+)*$"
      } else "^[0-9]+$"
      if (!grepl(expression, value)) stop("Invalid value for --", name)
      values[[name]] <- as.numeric(strsplit(value, ",", fixed = TRUE)[[1]])
    }
    i <- i + 1L
  }
  names(values) <- gsub("-", ".", names(values), fixed = TRUE)
  do.call(make.config, values)
}
