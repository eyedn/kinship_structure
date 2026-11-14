# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# check.state.R
# ______________________________________________________________________________


check.state <- function(state) {
  individuals <- state$individuals
  k <- state$kinship
  stopifnot(is.matrix(k), is.numeric(k),
            identical(dim(k), rep(nrow(individuals), 2L)),
            !anyDuplicated(individuals$id),
            identical(rownames(k), individuals$id),
            identical(colnames(k), individuals$id),
            all(is.finite(k)), all(k >= 0 & k <= 1),
            all(is.finite(individuals$inbreeding)),
            all(individuals$inbreeding >= 0 & individuals$inbreeding <= 1),
            isTRUE(all.equal(k, t(k), tolerance = 1e-14)),
            isTRUE(all.equal(unname(diag(k)),
                             (1 + individuals$inbreeding) / 2,
                             tolerance = 1e-14)))
  degree <- state$degree
  stopifnot(is.matrix(degree), is.numeric(degree),
            identical(dimnames(degree), dimnames(k)),
            identical(dim(degree), dim(k)), !anyNA(degree),
            all(degree >= 0),
            all(degree[is.finite(degree)] == floor(degree[is.finite(degree)])),
            all(diag(degree) == 0),
            sum(degree == 0) == nrow(degree),
            identical(degree, t(degree)))
  invisible(NULL)
}
