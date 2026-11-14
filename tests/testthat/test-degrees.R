# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# test-degrees.R
# ______________________________________________________________________________

testthat::test_that('pedigree distances distinguish ancestors and relatives', {
  state <- initialize.state(8)
  ids <- state$individuals$id
  testthat::expect_equal(unname(diag(state$degree)), rep(0, 8))
  testthat::expect_true(all(is.infinite(state$degree[upper.tri(state$degree)])))
  parents <- rbind(ids[c(1, 2)], ids[c(1, 2)], ids[c(3, 4)],
                   ids[c(5, 6)], ids[c(7, 8)], ids[c(1, 3)])
  state <- advance.state(state, parents)
  kids <- tail(state$individuals$id, 6)
  testthat::expect_equal(state$degree[kids[1], ids[1]], 1)
  testthat::expect_equal(state$degree[kids[1], kids[2]], 2)
  testthat::expect_equal(state$degree[kids[1], kids[6]], 2)
  testthat::expect_equal(state$degree[ids[1], ids[2]], Inf)
  testthat::expect_equal(state$degree[kids[1], kids[3]], Inf)
  state <- advance.state(state, rbind(kids[c(1, 3)], kids[c(2, 4)],
                                     kids[c(1, 2)]))
  grandkids <- tail(state$individuals$id, 3)
  testthat::expect_equal(state$degree[grandkids[1], grandkids[2]], 4)
  testthat::expect_equal(state$degree[grandkids[3], ids[1]], 2)
  testthat::expect_gt(tail(state$individuals$inbreeding, 1), 0)
})

testthat::test_that('rolling distances match full ancestor intersections', {
  sizes <- c(8, 6, 9, 5, 4, 7, 3, 6)
  state <- initialize.state(sizes[1])
  ancestors <- setNames(lapply(state$individuals$id, function(id) {
    setNames(0, id)
  }), state$individuals$id)
  for (g in seq_len(length(sizes) - 1L)) {
    previous <- state$individuals$id[state$individuals$generation == g - 1L]
    i <- seq_len(sizes[g + 1L])
    parents <- cbind(previous[(i - 1L) %% length(previous) + 1L],
                     previous[i %% length(previous) + 1L])
    before <- state$degree
    state <- advance.state(state, parents)
    kids <- tail(state$individuals$id, nrow(parents))
    for (j in seq_along(kids)) {
      # Store shortest upward paths to every ancestor, including oneself.
      paths <- c(ancestors[[parents[j, 1]]] + 1,
                 ancestors[[parents[j, 2]]] + 1, setNames(0, kids[j]))
      ancestors[[kids[j]]] <- tapply(paths, names(paths), min)
    }
    active <- state$individuals$id
    reference <- outer(active, active, Vectorize(function(a, b) {
      common <- intersect(names(ancestors[[a]]), names(ancestors[[b]]))
      if (!length(common)) return(Inf)
      min(ancestors[[a]][common] + ancestors[[b]][common])
    }))
    dimnames(reference) <- list(active, active)
    testthat::expect_equal(state$degree, reference)
    retained <- intersect(rownames(before), active)
    testthat::expect_equal(state$degree[retained, retained],
                          before[retained, retained])
    testthat::expect_silent(check.state(state))
  }
  testthat::expect_false(any(grepl('^G0_', state$individuals$id)))
  testthat::expect_true(any(is.finite(state$degree[upper.tri(state$degree)])))
  broken <- state
  broken$degree[1, 2] <- -1
  testthat::expect_error(check.state(broken))
})

testthat::test_that('degree summaries complete categories across the run', {
  result <- run.simulation(make.config(generations = 8,
                                       population.sizes = rep(6, 8)))
  data <- result$degree.histograms
  testthat::expect_named(
    data, c('generation', 'label', 'degree', 'count', 'proportion'))
  finite <- data$degree[is.finite(data$degree)]
  categories <- c(seq_len(max(finite)), Inf)
  for (g in 0:7) {
    rows <- data[data$generation == g, ]
    testthat::expect_equal(rows$degree, categories)
    testthat::expect_equal(sum(rows$count),
                          result$generations$pair.count[g + 1])
    testthat::expect_equal(sum(rows$proportion), 1)
  }
  founders <- data[data$generation == 0, ]
  testthat::expect_true(all(founders$count[is.finite(founders$degree)] == 0))
  testthat::expect_equal(founders$proportion[is.infinite(founders$degree)], 1)
  state <- result$final.state
  direct <- table(state$degree[upper.tri(state$degree)])
  last <- data[data$generation == 7, ]
  testthat::expect_equal(last$count[match(as.numeric(names(direct)),
                                         last$degree)], as.numeric(direct))
  memory <- matrix.memory(result$config)
  testthat::expect_equal(memory$matrix.bytes, 16 * memory$max.active.size^2)
})

testthat::test_that('six snapshots span the complete generation range', {
  for (g in c(1:6, 50, 5000)) {
    selected <- snapshot.generations(g)
    testthat::expect_length(selected, min(g, 6))
    testthat::expect_equal(range(selected), c(0, g - 1))
    if (g < 6) testthat::expect_equal(selected, seq.int(0, g - 1))
    if (g >= 6) {
      testthat::expect_true(all(abs(diff(selected) - (g - 1) / 5) <= 1))
    }
  }
  testthat::expect_equal(snapshot.generations(5000),
                        c(0, 1000, 2000, 2999, 3999, 4999))
})

testthat::test_that('degree plots share categories and manuscript theme', {
  result <- run.simulation(make.config(generations = 6,
                                       population.sizes = rep(4, 6)))
  data <- result$degree.histograms
  plot <- plot.histograms(data, result$generations, faceted = TRUE)
  built <- ggplot2::ggplot_build(plot)
  testthat::expect_equal(length(built$layout$panel_params), 6)
  testthat::expect_equal(plot$labels$x,
                        'Pedigree distance (parent–child steps)')
  testthat::expect_equal(tail(levels(plot$data$category), 1), 'Unrelated')
  testthat::expect_equal(sort(built$data[[1]]$ymax),
                        sort(log1p(100 * data$proportion)))
  testthat::expect_true(all(built$data[[2]]$y == 0))
  single <- plot.histograms(data, result$generations, selected = 0)
  single.built <- ggplot2::ggplot_build(single)
  shown <- as.vector(single.built$layout$panel_params[[1]]$x$get_labels())
  testthat::expect_equal(shown, levels(plot$data$category))
  heatmap <- plot.heatmap(data)
  fill <- heatmap$scales$get_scales('fill')
  testthat::expect_equal(fill$trans$name, 'identity')
  for (p in list(plot, single, heatmap,
                 plot.histograms(result$histograms, result$generations))) {
    testthat::expect_equal(p$theme$text$size, 24)
    testthat::expect_equal(p$theme$strip.text$face, 'plain')
    testthat::expect_s3_class(p$theme$strip.background, 'element_blank')
    testthat::expect_equal(p$theme$legend.position, 'top')
    testthat::expect_equal(p$theme$legend.direction, 'horizontal')
  }
})
