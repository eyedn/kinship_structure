# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# make.degree.config.R
# ______________________________________________________________________________


make.degree.config <- function(generations = 100L,
                               population.sizes = c(100L, 1000L, 10000L,
                                                    100000L),
                               seed = 1L,
                               output.dir = "~/scratch/kinship_structure",
                               fps = 25L, block.size = 512L) {
  values <- list(generations = generations, seed = seed, fps = fps,
                 block.size = block.size)
  for (name in names(values)) {
    value <- values[[name]]
    if (!is.numeric(value) || length(value) != 1L || is.na(value) ||
        !is.finite(value) || value != floor(value) ||
        value < ifelse(name == "seed", 0, 1) ||
        value > .Machine$integer.max) stop("Invalid ", name)
  }
  if (block.size > 4096) stop("block.size must not exceed 4096")
  # 255 is unrelated; the largest possible finite path is 2 * (G - 1).
  if (2 * (generations - 1) > 254) {
    stop("generations exceed raw-byte encoding (maximum 128).")
  }
  if (!is.numeric(population.sizes) || !length(population.sizes) ||
      anyNA(population.sizes) || any(!is.finite(population.sizes)) ||
      any(population.sizes < 2 | population.sizes != floor(population.sizes)) ||
      any(population.sizes > floor(.Machine$integer.max / 3)) ||
      anyDuplicated(population.sizes)) {
    stop("Invalid independent population sizes")
  }
  if (!is.character(output.dir) || length(output.dir) != 1L ||
      is.na(output.dir) || !nzchar(trimws(output.dir))) {
    stop("Invalid output.dir")
  }
  list(generations = as.integer(generations),
       population.sizes = as.integer(population.sizes), seed = as.integer(seed),
       output.dir = output.dir, fps = as.integer(fps),
       block.size = as.integer(block.size))
}
