# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# matrix.memory.R
# ______________________________________________________________________________


matrix.memory <- function(config) {
  active.sizes <- vapply(seq_len(config$generations), function(i) {
    sum(as.double(config$population.sizes[seq.int(max(1L, i - 2L), i)]))
  }, numeric(1))
  list(max.active.size = max(active.sizes),
       matrix.bytes = 16 * max(active.sizes)^2)
}
