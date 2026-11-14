# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# advance.degrees.R
# ______________________________________________________________________________


advance.degrees <- function(old, p, q) {
  # Paths go upward to a common ancestor; descendants cannot shorten old paths.
  cross <- 1 + pmin(old[p, , drop = FALSE], old[q, , drop = FALSE])
  children <- 2 + pmin(old[p, p, drop = FALSE], old[p, q, drop = FALSE],
                       old[q, p, drop = FALSE], old[q, q, drop = FALSE])
  diag(children) <- 0
  rbind(cbind(old, t(cross)), cbind(cross, children))
}
