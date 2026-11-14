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
  packages <- read.csv(file.path(first, 'package_versions.csv'))$package
  testthat::expect_true('magick' %in% packages)
  testthat::expect_false('gifski' %in% packages)
  testthat::expect_equal(min(result$final.state$individuals$generation), 1)
  testthat::expect_setequal(list.files(first),
    c('configuration.R', 'configuration.rds', 'final_state.rds',
      'generations.csv', 'histograms.csv', 'degree_histograms.csv',
      'package_versions.csv',
      'seed.txt', 'session_info.txt'))
})

testthat::test_that('CLI and interactive runs agree with automatic cores', {
  root <- file.path(SCRIPT.DIR, 'tests', 'artifacts', 'integration')
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  output <- tempfile('cli_', tmpdir = root)
  logs <- system2(file.path(R.home('bin'), 'Rscript'),
    c(shQuote(file.path(SCRIPT.DIR, 'simulate_kinship.R')),
      '--generations', '2', '--population-sizes', '4,3', '--seed', '9',
      '--output-dir', shQuote(output)),
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
    c('histograms_first10_faceted.png', 'histograms_faceted.png',
      'kinship_heatmap.png', 'kinship_histogram.gif',
      'degree_histograms_first10_faceted.png',
      'degree_histograms_faceted.png', 'degree_heatmap.png',
      'degree_histogram.gif'))
  degree <- read.csv(file.path(run.dir, 'degree_histograms.csv'))
  testthat::expect_equal(degree$degree, result$degree.histograms$degree)
  testthat::expect_equal(degree$count, result$degree.histograms$count)
  testthat::expect_equal(degree$proportion, result$degree.histograms$proportion)
  for (metric in c('kinship', 'degree')) {
    gif <- magick::image_read(file.path(run.dir, 'figures',
                                        paste0(metric, '_histogram.gif')))
    testthat::expect_equal(nrow(magick::image_info(gif)), 2L)
  }
  old.plan <- future::plan()
  before <- tempfile('regenerated_', tmpdir = root)
  actual <- render.figures(
    saved, read.csv(file.path(run.dir, 'generations.csv')), before,
    degree.histograms = degree)
  testthat::expect_equal(future::plan(), old.plan)
  testthat::expect_equal(actual$workers,
                        min(resolve.available.cores(future::availableCores(which = "all")),
                            6L))
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
                             degree.histograms = result$degree.histograms)
  testthat::expect_equal(future::plan(), old.plan)
  testthat::expect_equal(rendered$snapshots, 0L)
  testthat::expect_identical(rendered$early.snapshots, 0L)
  testthat::expect_identical(rendered$animation.generations, 0L)
  gif <- file.path(output, 'kinship_histogram.gif')
  testthat::expect_true(file.exists(gif))
  testthat::expect_equal(nrow(magick::image_info(magick::image_read(gif))), 1L)
  degree.gif <- file.path(output, 'degree_histogram.gif')
  testthat::expect_equal(
    nrow(magick::image_info(magick::image_read(degree.gif))), 1L)
})


testthat::test_that('entry point runs directly when sourced', {
  expressions <- parse(file.path(SCRIPT.DIR, 'simulate_kinship.R'))
  testthat::expect_false(any(vapply(expressions, function(expression) {
    is.call(expression) && identical(expression[[1]], as.name('if'))
  }, logical(1))))
  text <- readLines(file.path(SCRIPT.DIR, 'simulate_kinship.R'))
  testthat::expect_false(any(grepl('tryCatch|quit\\(', text)))
  testthat::expect_false('workers' %in% names(formals(make.config)))
  testthat::expect_false('workers' %in% names(formals(render.figures)))
})

testthat::test_that('source executes the workflow and prints figure paths', {
  root <- file.path(SCRIPT.DIR, 'tests', 'artifacts', 'live')
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  output <- tempfile('source_', tmpdir = root)
  cli.output <- output
  home <- path.expand('~')
  if (startsWith(output, paste0(home, '/'))) {
    cli.output <- paste0('~', substring(output, nchar(home) + 1L))
  }
  expression <- paste0(
    'Sys.setenv(SLURM_CPUS_PER_TASK = "1"); ',
    'options(parallelly.availableCores.methods = c("Slurm", "system")); ',
    'source(', deparse(file.path(SCRIPT.DIR, 'simulate_kinship.R')), '); ',
    'stopifnot(file.exists(file.path(FIGURES.DIR, ',
    '"kinship_histogram.gif")), file.exists(file.path(FIGURES.DIR, ',
    '"degree_histogram.gif")), RENDER.INFO$workers == 1L)')
  logs <- system2(file.path(R.home('bin'), 'Rscript'),
    c('-e', shQuote(expression), '--generations', '2',
      '--population-sizes', '4,3', '--output-dir', shQuote(cli.output)),
    stdout = TRUE, stderr = TRUE)
  testthat::expect_null(attr(logs, 'status'),
                        info = paste(logs, collapse = '\n'))
  testthat::expect_true(any(grepl('Figures directory:', logs, fixed = TRUE)))
  testthat::expect_true(any(grepl('Animation:', logs, fixed = TRUE)))
  testthat::expect_true(any(grepl('Detected 1 available CPUs', logs,
                                 fixed = TRUE)))
})

testthat::test_that('saved summaries render without main-script defaults', {
  isolated <- new.env(parent = baseenv())
  for (helper in list.files(file.path(SCRIPT.DIR, 'R_utils'),
                             pattern = '\\.R$', full.names = TRUE)) {
    sys.source(helper, envir = isolated)
  }
  result <- run.simulation(make.config(generations = 1,
                                       population.sizes = 2))
  output <- file.path(SCRIPT.DIR, 'tests', 'artifacts', 'isolated_replay')
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  historical <- file.path(output, 'histogram_G0.png')
  writeLines('historical snapshot', historical)
  testthat::expect_no_error(isolated$render.figures(
    result$histograms, result$generations, output, fps = 5L))
  testthat::expect_identical(readLines(historical), 'historical snapshot')
  testthat::expect_true(all(file.exists(file.path(output, c(
    'histograms_faceted.png', 'histograms_first10_faceted.png',
    'kinship_heatmap.png', 'kinship_histogram.gif')))))
})


testthat::test_that('stepped GIFs render selected generations at 25 fps', {
  result <- run.simulation(make.config(generations = 12,
                                       population.sizes = rep(6L, 12)))
  output <- file.path(SCRIPT.DIR, 'tests', 'artifacts', 'stepped_render')
  rendered <- render.figures(result$histograms, result$generations, output,
                             degree.histograms = result$degree.histograms)
  testthat::expect_identical(rendered$animation.generations, c(0L, 5L, 10L, 11L))
  testthat::expect_identical(rendered$early.snapshots, 0:9)
  testthat::expect_equal(length(list.files(output, pattern = '\\.png$')), 6L)
  for (metric in c('kinship', 'degree')) {
    path <- file.path(output, paste0(metric, '_histogram.gif'))
    gif <- magick::image_read(path)
    testthat::expect_equal(nrow(magick::image_info(gif)), 4L)
    bytes <- readBin(path, 'raw', n = file.info(path)$size)
    starts <- which(bytes == as.raw(0x21))
    controls <- starts[vapply(starts, function(i) {
      identical(bytes[seq.int(i, min(i + 2L, length(bytes)))],
                as.raw(c(0x21, 0xf9, 0x04)))
    }, logical(1))]
    delays <- vapply(controls, function(i) {
      as.integer(bytes[i + 4L]) + 256L * as.integer(bytes[i + 5L])
    }, integer(1))
    testthat::expect_identical(delays, rep(4L, 4L))
  }
})
