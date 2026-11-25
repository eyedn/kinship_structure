# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# accumulate.degree.counts.R
# ______________________________________________________________________________


accumulate.degree.counts <- function(counts, values) {
  as.double(counts) + tabulate(as.integer(values) + 1L, nbins = 256L)
}
