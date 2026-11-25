# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# initialize.degree.state.R
# ______________________________________________________________________________


initialize.degree.state <- function(population.size, block.size = 512L) {
  groups <- split(seq_len(population.size),
                  ceiling(seq_len(population.size) / block.size))
  blocks <- lapply(seq_along(groups), function(k) {
    list(key = as.character(k), ids = groups[[k]], generation = 0L)
  })
  tiles <- new.env(hash = TRUE, parent = emptyenv())
  for (b in seq_along(blocks)) {
    for (a in seq_len(b)) {
      n <- if (a == b) choose(length(groups[[a]]), 2) else
        as.double(length(groups[[a]])) * length(groups[[b]])
      assign(paste(a, b, sep = ":"),
             list(steps = rep(as.raw(255), n),
                  relationship = rep(as.raw(255), n)), envir = tiles)
    }
  }
  list(individuals = data.frame(id = seq_len(population.size), generation = 0L,
                                parent.1 = NA_integer_, parent.2 = NA_integer_),
       blocks = blocks, tiles = tiles, block.size = block.size,
       block.index = rep(seq_along(groups), lengths(groups)),
       local.index = sequence(lengths(groups)),
       next.id = as.double(population.size) + 1,
       next.block = length(blocks) + 1L)
}
