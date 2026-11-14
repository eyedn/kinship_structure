# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# run.simulation.R
# ______________________________________________________________________________


run.simulation <- function(config = make.config()) {
  config <- do.call(make.config, config)
  estimate <- matrix.memory(config)
  message(sprintf(
    "Largest active population: %.0f individuals; %.2f MiB (both matrices).",
    estimate$max.active.size, estimate$matrix.bytes / 1024^2))
  message("Working memory also includes matrix copies and summary row blocks.")
  old.kind <- RNGkind()
  had.seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had.seed) old.seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    do.call(RNGkind, as.list(old.kind))
    if (had.seed) {
      assign(".Random.seed", old.seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(config$seed)
  state <- initialize.state(config$population.sizes[1])
  summaries <- vector("list", config$generations)
  for (generation in seq.int(0L, config$generations - 1L)) {
    if (generation > 0L) {
      previous <- state$individuals$id[
        state$individuals$generation == generation - 1L]
      parents <- sample.parents(previous,
                                config$population.sizes[generation + 1L])
      state <- advance.state(state, parents)
    }
    check.state(state)
    summaries[[generation + 1L]] <- summarize.state(state, config$block.size)
  }
  list(config = config, final.state = state,
       generations = dplyr::bind_rows(lapply(summaries, `[[`, "generations")),
       histograms = dplyr::bind_rows(lapply(summaries, `[[`, "histograms")),
       degree.histograms = complete.degree.histograms(dplyr::bind_rows(
         lapply(summaries, `[[`, "degree.histograms"))))
}
