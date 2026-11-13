# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# initialize.state.R
# ______________________________________________________________________________


initialize.state <- function(population.size) {
  ids <- paste0("G0_I", seq_len(population.size))
  individuals <- tibble::tibble(
    id = ids, generation = 0L, parent.1 = NA_character_,
    parent.2 = NA_character_, inbreeding = 0)
  kinship <- diag(0.5, population.size)
  dimnames(kinship) <- list(ids, ids)
  list(individuals = individuals, kinship = kinship)
}
