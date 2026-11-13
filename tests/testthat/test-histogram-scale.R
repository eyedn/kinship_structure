# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# test-histogram-scale.R
# ______________________________________________________________________________

testthat::test_that('histogram scales retain zero and the requested labels', {
  result <- run.simulation(make.config(generations = 3,
                                       population.sizes = rep(4L, 3)))
  plots <- list(
    plot.histograms(result$histograms, result$generations),
    plot.histograms(result$histograms, result$generations, selected = 1),
    plot.histograms(result$histograms, result$generations, faceted = TRUE))
  for (plot in plots) {
    scale <- plot$scales$get_scales('y')
    testthat::expect_equal(scale$breaks, c(0, .25, .5, .75, 1))
    testthat::expect_equal(scale$labels, c('0', '.25', '.5', '.75', '1'))
    positions <- scale$trans$transform(c(0, .25, .5, .75, 1))
    testthat::expect_true(all(is.finite(positions)))
    testthat::expect_equal(positions[1], 0)
    testthat::expect_true(all(diff(positions) > 0))
    testthat::expect_true(all(diff(diff(positions)) < 0))
  }
  for (plot in plots[2:3]) {
    built <- ggplot2::ggplot_build(plot)
    testthat::expect_true(all(is.finite(built$data[[1]]$ymin)))
    testthat::expect_true(all(is.finite(built$data[[1]]$ymax)))
    testthat::expect_true(all(built$data[[2]]$y == 0))
  }
  testthat::expect_identical(plots[[1]]$data$proportion,
                            result$histograms$proportion)
})
