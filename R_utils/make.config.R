# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# make.config.R
# ______________________________________________________________________________


make.config <- function(
    generations = DEFAULT.GENERATIONS, population.sizes = NULL,
    seed = DEFAULT.SEED,
    output.dir = DEFAULT.OUTPUT.DIR, fps = DEFAULT.FPS,
    block.size = DEFAULT.BLOCK.SIZE,
    gif.generation.step = if (exists("DEFAULT.GIF.GENERATION.STEP"))
      DEFAULT.GIF.GENERATION.STEP else 3L) {
  scalars <- list(generations = generations, seed = seed,
                  fps = fps, block.size = block.size,
                  gif.generation.step = gif.generation.step)
  for (name in names(scalars)) {
    value <- scalars[[name]]
    minimum <- if (name == "seed") 0 else 1
    if (!is.numeric(value) || length(value) != 1L || is.na(value) ||
        !is.finite(value) || value != floor(value) || value < minimum ||
        value > .Machine$integer.max) {
      stop(name, " must be an integer in [", minimum, ", ",
           .Machine$integer.max, "].", call. = FALSE)
    }
  }
  if (is.null(population.sizes)) {
    population.sizes <- rep(DEFAULT.POPULATION.SIZE, generations)
  }
  if (!is.numeric(population.sizes) ||
      length(population.sizes) != generations ||
      anyNA(population.sizes) || any(!is.finite(population.sizes)) ||
      any(population.sizes < 2 | population.sizes != floor(population.sizes)) ||
      any(population.sizes > .Machine$integer.max)) {
    stop("population.sizes must contain exactly generations integers >= 2.",
         call. = FALSE)
  }
  if (!is.character(output.dir) || length(output.dir) != 1L ||
      is.na(output.dir) || !nzchar(trimws(output.dir))) {
    stop("output.dir must be a nonempty path.", call. = FALSE)
  }
  list(generations = as.integer(generations),
       population.sizes = as.integer(population.sizes), seed = as.integer(seed),
       output.dir = output.dir,
       fps = as.integer(fps), block.size = as.integer(block.size),
       gif.generation.step = as.integer(gif.generation.step))
}
