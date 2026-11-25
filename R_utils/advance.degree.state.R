# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# advance.degree.state.R
# ______________________________________________________________________________


advance.degree.state <- function(state, parents) {
  generation <- max(state$individuals$generation) + 1L
  previous <- state$individuals$id[
    state$individuals$generation == generation - 1L]
  if (!is.matrix(parents) || ncol(parents) != 2L || nrow(parents) < 2L ||
      anyNA(parents) || any(!parents %in% previous) ||
      any(parents[, 1] == parents[, 2])) stop("Invalid parent assignments")
  # State owns its environment. Advancing consumes it and frees expired tiles.
  keep <- state$individuals$generation >= generation - 2L
  expired <- vapply(state$blocks, function(x) x$generation < generation - 2L,
                    logical(1))
  old.blocks <- state$blocks
  if (any(expired)) {
    keys <- vapply(old.blocks, `[[`, character(1), "key")
    for (b in seq_along(keys)) for (a in seq_len(b)) {
      if (expired[a] || expired[b]) {
        rm(list = paste(keys[a], keys[b], sep = ":"), envir = state$tiles)
      }
    }
  }
  state$individuals <- state$individuals[keep, , drop = FALSE]
  rownames(state$individuals) <- NULL
  state$blocks <- old.blocks[!expired]
  sizes <- lengths(lapply(state$blocks, `[[`, "ids"))
  state$block.index <- rep(seq_along(sizes), sizes)
  state$local.index <- sequence(sizes)
  p <- match(parents[, 1], state$individuals$id)
  q <- match(parents[, 2], state$individuals$id)
  old.n <- nrow(state$individuals)
  n <- nrow(parents)
  ids <- seq(from = state$next.id, length.out = n)
  groups <- split(seq_len(n), ceiling(seq_len(n) / state$block.size))
  new.blocks <- lapply(seq_along(groups), function(k) {
    list(key = as.character(state$next.block + k - 1L),
         ids = ids[groups[[k]]], generation = generation)
  })
  all.blocks <- c(state$blocks, new.blocks)
  positions <- split(seq_len(old.n + n), rep(seq_along(all.blocks),
    lengths(lapply(all.blocks, `[[`, "ids"))))
  for (b in seq.int(length(state$blocks) + 1L, length(all.blocks))) {
    for (a in seq_len(b)) {
      pairs <- degree.tile.pairs(positions[[a]], positions[[b]], a == b)
      i <- pairs$i
      j <- pairs$j - old.n
      children <- i > old.n
      values <- list()
      for (metric in c("steps", "relationship")) {
        result <- numeric(length(i))
        old <- which(!children)
        if (length(old)) {
          result[old] <- 1 + pmin(
            degree.values(state, i[old], p[j[old]], metric),
            degree.values(state, i[old], q[j[old]], metric))
        }
        young <- which(children)
        if (length(young)) {
          u <- i[young] - old.n
          v <- j[young]
          result[young] <- 2 + pmin(
            degree.values(state, p[u], p[v], metric),
            degree.values(state, p[u], q[v], metric),
            degree.values(state, q[u], p[v], metric),
            degree.values(state, q[u], q[v], metric))
          if (metric == "relationship") {
            siblings <- (p[u] == p[v] & q[u] == q[v]) |
              (p[u] == q[v] & q[u] == p[v])
            result[young[siblings]] <- 1
          }
        }
        if (any(is.finite(result) & result > 254)) stop("Encoding overflow")
        result[is.infinite(result)] <- 255
        values[[metric]] <- as.raw(result)
      }
      assign(paste(all.blocks[[a]]$key, all.blocks[[b]]$key, sep = ":"),
             values, envir = state$tiles)
    }
  }
  state$blocks <- all.blocks
  state$individuals <- rbind(state$individuals,
    data.frame(id = ids, generation = generation,
               parent.1 = parents[, 1], parent.2 = parents[, 2]))
  sizes <- lengths(lapply(all.blocks, `[[`, "ids"))
  state$block.index <- rep(seq_along(sizes), sizes)
  state$local.index <- sequence(sizes)
  state$next.id <- state$next.id + n
  state$next.block <- state$next.block + length(new.blocks)
  state
}
