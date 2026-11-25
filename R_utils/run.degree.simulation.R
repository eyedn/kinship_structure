# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# run.degree.simulation.R
# ______________________________________________________________________________


run.degree.simulation <- function(config = make.degree.config(),
                                  population.size =
                                    config$population.sizes[1]) {
  config <- do.call(make.degree.config, config)
  if (length(population.size) != 1L ||
      !population.size %in% config$population.sizes) {
    stop("Size absent from config")
  }
  estimate <- degree.estimates(config, population.size)
  message(sprintf(paste0("N=%.0f: pair storage %.2f GB; ",
                         "temporary block allowance ",
                         "%.2f GB; output estimate %.2f GB (before overhead)."),
                  population.size, estimate$pair.bytes / 1e9,
                  estimate$temporary.bytes / 1e9, estimate$output.bytes / 1e9))
  old.kind <- RNGkind()
  had.seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had.seed) old.seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    do.call(RNGkind, as.list(old.kind))
    if (had.seed) assign(".Random.seed", old.seed, envir = .GlobalEnv) else
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
        rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(config$seed)
  state <- initialize.degree.state(population.size, config$block.size)
  steps <- relationship <- summaries <- parents <- vector("list",
                                                         config$generations)
  start <- proc.time()[["elapsed"]]
  for (g in seq.int(0L, config$generations - 1L)) {
    if (g > 0L) {
      previous <- state$individuals$id[state$individuals$generation == g - 1L]
      assignments <- sample.parents(previous, population.size)
      state <- advance.degree.state(state, assignments)
    }
    parents[[g + 1L]] <- tail(state$individuals, population.size)
    steps[[g + 1L]] <- summarize.degree.state(state, "steps")
    relationship[[g + 1L]] <- summarize.degree.state(state, "relationship")
    cohorts <- table(state$individuals$generation)
    summaries[[g + 1L]] <- data.frame(
      generation = g, label = paste0("G", g),
      cohort.sizes = paste(paste0("G", names(cohorts), "=", cohorts),
                           collapse = ", "),
      active.size = nrow(state$individuals),
      pair.count = choose(as.double(nrow(state$individuals)), 2),
      elapsed.seconds = proc.time()[["elapsed"]] - start)
    message("N=", population.size, " completed G", g)
  }
  trim <- function(data) {
    data <- do.call(rbind, data)
    maximum <- max(c(0, data$degree[is.finite(data$degree) & data$count > 0]))
    data[data$degree <= maximum | is.infinite(data$degree), ]
  }
  list(config = config, population.size = population.size,
       final.state = state, parents = do.call(rbind, parents),
       generations = do.call(rbind, summaries), steps = trim(steps),
       relationship = trim(relationship))
}
