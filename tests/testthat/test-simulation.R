# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# test-simulation.R
# ______________________________________________________________________________

source(file.path('..', '..', 'simulate_kinship.R'))

testthat::test_that('configuration and CLI enforce generation contracts', {
  testthat::expect_true(exists('make.config', mode = 'function'))
  testthat::expect_equal(make.config()$population.sizes, rep(100L, 100))
  config <- parse.cli(c('--generations', '2', '--population-sizes=3,4',
                        '--seed', '7', '--workers=1'))
  testthat::expect_equal(config$population.sizes, c(3L, 4L))
  testthat::expect_equal(config$seed, 7L)
  for (args in list(c('--generations', '0'), c('--seed', '-1'),
                    c('--workers', '1.5'), c('--unknown', '1'),
                    c('--generations', '2', '--population-sizes', '2'),
                    c('--population-sizes', '2,'), c('--output-dir', ''),
                    c('--seed', '1', '--seed', '2'))) {
    testthat::expect_error(parse.cli(args))
  }
})

testthat::test_that('known pedigrees have their expected coefficients', {
  founders <- initialize.state(4)
  ids <- founders$individuals$id
  children <- advance.state(founders, cbind(ids[c(1, 1, 1, 3)],
                                           ids[c(2, 2, 3, 4)]))
  kids <- tail(children$individuals$id, 4)
  k <- children$kinship
  testthat::expect_equal(k[ids[1], ids[2]], 0)
  testthat::expect_equal(k[kids[1], ids[1]], 0.25)
  testthat::expect_equal(k[kids[1], kids[2]], 0.25)
  testthat::expect_equal(k[kids[1], kids[3]], 0.125)
  grandchildren <- advance.state(children,
                                 rbind(kids[c(1, 2)], kids[c(3, 4)]))
  testthat::expect_equal(tail(grandchildren$individuals$inbreeding, 2)[1],
                        0.25)
})

testthat::test_that('rolling matrices match a scalar full-pedigree reference', {
  sizes <- c(5, 3, 6, 4, 2, 5, 3)
  state <- initialize.state(sizes[1])
  reference <- state$kinship
  for (generation in seq_len(length(sizes) - 1L)) {
    previous <- state$individuals$id[
      state$individuals$generation == generation - 1L]
    # Fixed assignments exercise shared parents and changing cohort sizes.
    parents <- cbind(previous[(seq_len(sizes[generation + 1]) - 1) %%
                                length(previous) + 1],
                     previous[seq_len(sizes[generation + 1]) %%
                                length(previous) + 1])
    state <- advance.state(state, parents)
    for (i in seq_len(nrow(parents))) {
      id <- tail(state$individuals$id, nrow(parents))[i]
      old.ids <- rownames(reference)
      p <- parents[i, 1]
      q <- parents[i, 2]
      expanded <- matrix(0, nrow(reference) + 1, ncol(reference) + 1,
                         dimnames = list(c(old.ids, id), c(old.ids, id)))
      expanded[old.ids, old.ids] <- reference
      for (j in old.ids) {
        expanded[id, j] <- (reference[p, j] + reference[q, j]) / 2
        expanded[j, id] <- expanded[id, j]
      }
      expanded[id, id] <- (1 + reference[p, q]) / 2
      reference <- expanded
    }
    active <- state$individuals$id
    testthat::expect_equal(state$kinship, reference[active, active])
    testthat::expect_silent(check.state(state))
    testthat::expect_equal(unique(state$individuals$generation),
                          seq.int(max(0, generation - 2), generation))
    summary <- summarize.state(state, block.size = 2)
    testthat::expect_equal(summary$generations$pair.count,
                          choose(length(active), 2))
    testthat::expect_equal(sum(summary$histograms$count),
                          choose(length(active), 2))
    testthat::expect_equal(sum(summary$histograms$proportion), 1)
    testthat::expect_equal(summary$generations$mean.kinship,
                          mean(state$kinship[upper.tri(state$kinship)]))
  }
})

testthat::test_that('histograms preserve zeros and close the final interval', {
  state <- initialize.state(5)
  values <- c(0, 0.01, 0.5, 0.99, 1, 0, 0.009, 0.1, 0.25, 0.75)
  state$kinship[upper.tri(state$kinship)] <- values
  state$kinship[lower.tri(state$kinship)] <-
    t(state$kinship)[lower.tri(state$kinship)]
  summary <- summarize.state(state, block.size = 2)
  testthat::expect_equal(nrow(summary$histograms), 100)
  testthat::expect_equal(summary$histograms$count[c(1, 2, 51, 100)],
                        c(3, 1, 1, 2))
  testthat::expect_equal(summary$generations$zero.count, 2)
  testthat::expect_true(any(summary$histograms$count == 0))
  testthat::expect_equal(sum(summary$histograms$count), 10)
})

testthat::test_that('endpoints, snapshots and RNG are reproducible', {
  for (g in c(1L, 2L, 50L)) {
    config <- make.config(generations = g, population.sizes = rep(4L, g))
    set.seed(99)
    before <- .Random.seed
    result <- run.simulation(config)
    testthat::expect_identical(.Random.seed, before)
    again <- run.simulation(config)
    testthat::expect_identical(result, again)
    testthat::expect_equal(tail(result$generations$label, 1),
                          paste0('G', g - 1))
    testthat::expect_equal(nrow(result$histograms), 100 * g)
    testthat::expect_equal(nrow(result$final.state$individuals), min(3, g) * 4)
    config$workers <- 2L
    parallel <- run.simulation(config)
    testthat::expect_identical(result$final.state, parallel$final.state)
    testthat::expect_identical(result$histograms, parallel$histograms)
  }
  testthat::expect_equal(snapshot.generations(50), c(0:5, 25L, 49L))
  testthat::expect_equal(snapshot.generations(1), 0L)
  testthat::expect_equal(snapshot.generations(2), 0:1)
  data <- run.simulation(make.config(generations = 12,
                                     population.sizes = rep(2L, 12)))
  plot <- plot.histograms(data$histograms, data$generations)
  testthat::expect_equal(levels(plot$data$frame.label),
                        unique(as.character(plot$data$frame.label)))
  testthat::expect_match(tail(levels(plot$data$frame.label), 1), '^G11 ')
  testthat::expect_equal(plot$scales$get_scales('x')$limits, c(0, 1))
})
