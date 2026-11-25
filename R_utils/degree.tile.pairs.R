# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# degree.tile.pairs.R
# ______________________________________________________________________________


degree.tile.pairs <- function(a, b, diagonal = FALSE) {
  if (diagonal) {
    n <- length(a)
    if (n < 2L) return(list(i = integer(), j = integer()))
    j <- rep.int(seq.int(2L, n), seq_len(n - 1L))
    i <- sequence(seq_len(n - 1L))
    return(list(i = a[i], j = a[j]))
  }
  list(i = rep(a, times = length(b)), j = rep(b, each = length(a)))
}
