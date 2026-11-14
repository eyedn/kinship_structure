# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# test-render-selections.R
# ______________________________________________________________________________

testthat::test_that('default animation includes both endpoints', {
  for (g in c(1, 2, 3, 4, 5, 7, 10, 12, 50, 5000)) {
    testthat::expect_identical(animation.generations(g),
      as.integer(unique(c(seq(0, g - 1, by = 3), g - 1))))
  }
  testthat::expect_length(animation.generations(5000), 1668L)
})

testthat::test_that('early facets and animation retain full-run scales', {
  for (n in c(1L, 7L, 12L)) {
    result <- run.simulation(make.config(generations = n,
                                         population.sizes = rep(4L, n)))
    early <- seq.int(0L, min(9L, n - 1L))
    for (data in list(result$histograms, result$degree.histograms)) {
      full <- plot.histograms(data, result$generations)
      panels <- plot.histograms(data, result$generations, early, TRUE)
      animated <- plot.histograms(data, result$generations,
                                   animation.generations(n))
      testthat::expect_identical(
        levels(animated$data$frame.label),
        unique(as.character(animated$data$frame.label)))
      built <- ggplot2::ggplot_build(panels)
      testthat::expect_identical(unique(panels$data$generation), early)
      testthat::expect_equal(panels$facet$params$ncol, 2L)
      testthat::expect_equal(as.integer(built$layout$layout$PANEL),
                            seq_along(early))
      for (plot in list(panels, animated)) {
        testthat::expect_equal(plot$scales$get_scales('y')$limits,
                              full$scales$get_scales('y')$limits)
        testthat::expect_true(any(plot$data$count == 0) || n == 1L)
        if ('degree' %in% names(data)) {
          testthat::expect_identical(levels(plot$data$category),
                                    levels(full$data$category))
          testthat::expect_true('Unrelated' %in% levels(plot$data$category))
        } else {
          testthat::expect_equal(plot$scales$get_scales('x')$limits, c(0, 1))
        }
      }
    }
  }
})

testthat::test_that('heatmaps use a linear blue-to-red rainbow', {
  result <- run.simulation(make.config(generations = 7,
                                       population.sizes = rep(4L, 7)))
  colors <- c('blue', 'cyan', 'green', 'yellow', 'orange', 'red')
  for (data in list(result$histograms, result$degree.histograms)) {
    plot <- plot.heatmap(data)
    built <- ggplot2::ggplot_build(plot)
    scale <- built$plot$scales$get_scales('fill')
    testthat::expect_equal(scale$limits, c(0, max(data$proportion)))
    testthat::expect_equal(scale$trans$transform(c(0, 0.25, 0.5, 1)),
                          c(0, 0.25, 0.5, 1))
    testthat::expect_identical(toupper(scale$palette(seq(0, 1, length.out = 6))),
                              toupper(grDevices::rgb(
                                t(grDevices::col2rgb(colors)),
                                maxColorValue = 255)))
    testthat::expect_identical(plot$data$proportion, data$proportion)
    testthat::expect_identical(plot$theme$legend.position, 'top')
    testthat::expect_identical(scale$guide$params$direction, 'horizontal')
  }
})
