# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# degree.estimates.R
# ______________________________________________________________________________


degree.estimates <- function(config, population.size) {
  active <- as.double(population.size) * min(3, config$generations)
  bytes <- 2 * choose(active, 2)
  list(max.active.size = active, pair.bytes = bytes,
       temporary.bytes = 256 * as.double(config$block.size)^2,
       # Uncompressed RDS plus conservative text, parent and figure allowances.
       output.bytes = bytes + 100 * population.size * config$generations +
         2e8 + 2e6 * config$generations)
}
