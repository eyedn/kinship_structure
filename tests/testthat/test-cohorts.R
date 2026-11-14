# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# test-cohorts.R
# ______________________________________________________________________________

testthat::test_that('GIF steps are configurable positive integers', {
  testthat::expect_equal(make.config()$gif.generation.step, 3L)
  for (g in c(1L, 2L, 4L, 5L, 12L, 5000L)) {
    for (step in c(1L, 3L, 7L)) {
      testthat::expect_identical(animation.generations(g, step),
        as.integer(unique(c(seq(0, g - 1, by = step), g - 1))))
    }
  }
  testthat::expect_length(animation.generations(5000), 1668L)
  for (step in list(0, -1, 1.5, NA, Inf, '3', c(1, 2))) {
    testthat::expect_error(make.config(gif.generation.step = step))
    testthat::expect_error(animation.generations(12, step))
  }
})

testthat::test_that('cohort counts match direct unordered pair enumeration', {
  state <- initialize.state(4)
  for (g in 0:4) {
    if (g > 0) {
      ids <- state$individuals$id[state$individuals$generation == g - 1]
      i <- seq_len(g + 2L)
      state <- advance.state(state,
        cbind(ids[(i - 1L) %% length(ids) + 1L],
              ids[i %% length(ids) + 1L]))
    }
    summary <- summarize.state(state, block.size = 2L)
    pairs <- combn(nrow(state$kinship), 2)
    offsets <- g - state$individuals$generation
    labels <- c('Child–child', 'Parent–parent', 'Grandparent–grandparent',
                'Child–parent', 'Child–grandparent', 'Parent–grandparent')
    lookup <- matrix(c(1, 4, 5, 4, 2, 6, 5, 6, 3), 3)
    groups <- lookup[cbind(offsets[pairs[1, ]] + 1L,
                           offsets[pairs[2, ]] + 1L)]
    sizes <- tabulate(offsets + 1L, nbins = 3L)
    category.totals <- c(choose(sizes, 2), sizes[1] * sizes[2],
                         sizes[1] * sizes[3], sizes[2] * sizes[3])
    for (metric in c('histograms', 'degree.histograms')) {
      aggregate <- summary[[metric]]
      grouped <- summary[[paste0(metric, '.by.cohort')]]
      testthat::expect_true(is.data.frame(grouped))
      testthat::expect_setequal(names(grouped), c(names(aggregate),
                                                 'cohort.pair'))
      key <- if (metric == 'histograms') 'bin' else 'degree'
      values <- if (key == 'bin') {
        findInterval(state$kinship[t(pairs)], seq(0, 1, length.out = 101),
                     rightmost.closed = TRUE)
      } else state$degree[t(pairs)]
      for (j in seq_along(labels)) {
        rows <- grouped[grouped$cohort.pair == labels[j], ]
        testthat::expect_equal(rows[[key]], aggregate[[key]])
        expected <- vapply(rows[[key]], function(x) {
          sum(groups == j & values == x)
        }, integer(1))
        testthat::expect_equal(rows$count, expected)
        testthat::expect_equal(sum(rows$count), category.totals[j])
        testthat::expect_equal(rows$proportion, expected / ncol(pairs))
      }
      totals <- dplyr::summarise(
        dplyr::group_by(grouped, .data[[key]]),
        count = sum(count), proportion = sum(proportion))
      testthat::expect_equal(totals$count, aggregate$count)
      testthat::expect_equal(totals$proportion, aggregate$proportion)
    }
  }
})

testthat::test_that('cohort stacks accumulate percentages before log1p', {
  result <- run.simulation(make.config(generations = 4,
                                       population.sizes = c(4, 3, 5, 2)))
  for (metric in c('histograms', 'degree.histograms')) {
    grouped <- result[[paste0(metric, '.by.cohort')]]
    plain <- plot.histograms(result[[metric]], result$generations, 0:3, TRUE)
    colored <- plot.histograms(grouped, result$generations, 0:3, TRUE)
    built <- ggplot2::ggplot_build(colored)
    testthat::expect_equal(colored$scales$get_scales('y')$limits,
                          plain$scales$get_scales('y')$limits)
    testthat::expect_equal(built$data[[1]]$ymin,
                          log1p(colored$data$ymin))
    testthat::expect_equal(built$data[[1]]$ymax,
                          log1p(colored$data$ymax))
    key <- if (metric == 'histograms') 'bin' else 'degree'
    tops <- dplyr::summarise(
      dplyr::group_by(colored$data, generation, .data[[key]]),
      top = max(ymax), .groups = 'drop')
    testthat::expect_equal(tops$top, 100 * plain$data$proportion)
    testthat::expect_equal(nrow(built$data[[2]]), sum(plain$data$count == 0))
    testthat::expect_true(all(built$data[[2]]$y == 0))
    fill <- built$plot$scales$get_scales('fill')
    testthat::expect_equal(unname(fill$palette(6)),
      c('#0072B2', '#E69F00', '#009E73', '#CC79A7', '#D55E00', '#56B4E9'))
    testthat::expect_equal(fill$get_limits(), cohort.pair.labels())
    testthat::expect_equal(fill$guide$params$nrow, 2L)
    if (key == 'degree') {
      testthat::expect_true('Unrelated' %in% levels(colored$data$category))
    }
  }
})


testthat::test_that('all six segments follow the legend from bottom to top', {
  labels <- cohort.pair.labels()
  counts <- c(3, 3, 3, 9, 9, 9)
  data <- tibble::tibble(
    generation = 2L, label = 'G2', bin = 1L, lower = 0, upper = 0.01,
    right.closed = FALSE, count = counts, proportion = counts / sum(counts),
    cohort.pair = labels)
  generations <- tibble::tibble(generation = 2L, label = 'G2',
                                cohort.sizes = 'G0=3, G1=3, G2=3')
  built <- ggplot2::ggplot_build(plot.histograms(data, generations))
  expected <- c(0, cumsum(100 * counts / sum(counts)))
  testthat::expect_equal(built$data[[1]]$ymin, log1p(head(expected, -1)))
  testthat::expect_equal(built$data[[1]]$ymax, log1p(tail(expected, -1)))
  testthat::expect_identical(built$data[[1]]$fill,
    c('#0072B2', '#E69F00', '#009E73', '#CC79A7', '#D55E00', '#56B4E9'))
  testthat::expect_length(built$data, 1L)
})
