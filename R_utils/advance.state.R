# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# advance.state.R
# ______________________________________________________________________________


advance.state <- function(state, parents) {
  generation <- max(state$individuals$generation) + 1L
  previous <- state$individuals$id[
    state$individuals$generation == generation - 1L]
  if (!is.matrix(parents) || ncol(parents) != 2L || nrow(parents) < 2L ||
      anyNA(parents) || any(!parents %in% previous) ||
      any(parents[, 1] == parents[, 2])) {
    stop("Each child needs two distinct parents from the previous cohort.")
  }
  # Drop the oldest cohort before allocating the next active matrix.
  keep <- state$individuals$generation >= generation - 2L
  individuals <- state$individuals[keep, ]
  old <- state$kinship[keep, keep, drop = FALSE]
  p <- match(parents[, 1], individuals$id)
  q <- match(parents[, 2], individuals$id)
  inbreeding <- old[cbind(p, q)]
  cross <- (old[p, , drop = FALSE] + old[q, , drop = FALSE]) / 2
  children <- (old[p, p, drop = FALSE] + old[p, q, drop = FALSE] +
                 old[q, p, drop = FALSE] + old[q, q, drop = FALSE]) / 4
  diag(children) <- (1 + inbreeding) / 2
  ids <- paste0("G", generation, "_I", seq_len(nrow(parents)))
  metadata <- tibble::tibble(
    id = ids, generation = generation, parent.1 = parents[, 1],
    parent.2 = parents[, 2], inbreeding = inbreeding)
  individuals <- dplyr::bind_rows(individuals, metadata)
  kinship <- rbind(cbind(old, t(cross)), cbind(cross, children))
  dimnames(kinship) <- list(individuals$id, individuals$id)
  list(individuals = individuals, kinship = kinship)
}
