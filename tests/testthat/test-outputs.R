# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# test-outputs.R
# ______________________________________________________________________________

source(file.path('..', '..', 'simulate_kinship.R'))

testthat::test_that('run directories preserve earlier outputs', {
  root <- file.path(SCRIPT.DIR, 'tests', 'artifacts', 'writing')
  result <- run.simulation(make.config(generations = 4,
                                       population.sizes = c(4, 3, 5, 2),
                                       output.dir = root))
  first <- write.results(result)
  files <- list.files(first, full.names = TRUE)
  hashes <- tools::md5sum(files)
  second <- write.results(result)
  testthat::expect_false(identical(first, second))
  testthat::expect_identical(tools::md5sum(files), hashes)
  testthat::expect_identical(readRDS(file.path(first, 'final_state.rds')),
                            result$final.state)
  testthat::expect_identical(readRDS(file.path(first, 'configuration.rds')),
                            result$config)
  testthat::expect_identical(dget(file.path(first, 'configuration.R')),
                            result$config)
  testthat::expect_equal(min(result$final.state$individuals$generation), 1)
  testthat::expect_setequal(list.files(first),
    c('configuration.R', 'configuration.rds', 'final_state.rds',
      'generations.csv', 'histograms.csv', 'package_versions.csv',
      'seed.txt', 'session_info.txt'))
})

testthat::test_that('CLI output matches interactive output with parallel plots', {
  root <- file.path(SCRIPT.DIR, 'tests', 'artifacts', 'integration')
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  output <- tempfile('cli_', tmpdir = root)
  logs <- system2(file.path(R.home('bin'), 'Rscript'),
    c(shQuote(file.path(SCRIPT.DIR, 'simulate_kinship.R')),
      '--generations', '2', '--population-sizes', '4,3', '--seed', '9',
      '--workers', '2', '--output-dir', shQuote(output)),
    stdout = TRUE, stderr = TRUE)
  testthat::expect_null(attr(logs, 'status'), info = paste(logs, collapse = '\n'))
  run.dir <- list.dirs(output, recursive = FALSE, full.names = TRUE)[1]
  config <- readRDS(file.path(run.dir, 'configuration.rds'))
  result <- run.simulation(config)
  testthat::expect_identical(readRDS(file.path(run.dir, 'final_state.rds')),
                            result$final.state)
  saved <- read.csv(file.path(run.dir, 'histograms.csv'))
  testthat::expect_equal(saved$proportion, result$histograms$proportion)
  testthat::expect_equal(saved$count, result$histograms$count)
  testthat::expect_setequal(list.files(file.path(run.dir, 'figures')),
    c('histogram_G0.png', 'histogram_G1.png', 'histograms_faceted.png',
      'kinship_heatmap.png', 'kinship_histogram.gif'))
  old.plan <- future::plan()
  before <- file.path(root, 'regenerated')
  actual <- render.figures(saved, read.csv(file.path(run.dir, 'generations.csv')),
                           before, workers = 1)
  testthat::expect_equal(future::plan(), old.plan)
  testthat::expect_equal(actual$workers, 1)
  for (file in list.files(before, pattern = '\\.png$')) {
    testthat::expect_identical(
      png::readPNG(file.path(before, file)),
      png::readPNG(file.path(run.dir, 'figures', file)))
  }
})

testthat::test_that('a single generation renders and restores the future plan', {
  result <- run.simulation(make.config(generations = 1,
                                       population.sizes = 2))
  output <- file.path(SCRIPT.DIR, 'tests', 'artifacts', 'single_generation')
  old.plan <- future::plan()
  rendered <- render.figures(result$histograms, result$generations, output,
                             workers = 2)
  testthat::expect_equal(future::plan(), old.plan)
  testthat::expect_equal(rendered$snapshots, 0L)
  testthat::expect_true(file.exists(file.path(output, 'kinship_histogram.gif')))
})
