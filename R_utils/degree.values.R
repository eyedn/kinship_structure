# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# degree.values.R
# ______________________________________________________________________________


degree.values <- function(state, i, j, metric = "steps") {
  if (!metric %in% c("steps", "relationship")) stop("Invalid metric")
  if (length(i) != length(j) || anyNA(i) || anyNA(j) ||
      any(i < 1 | j < 1 | i > nrow(state$individuals) |
          j > nrow(state$individuals))) stop("Invalid pair indices")
  sizes <- lengths(lapply(state$blocks, `[[`, "ids"))
  block <- state$block.index
  local <- state$local.index
  bi <- block[i]
  bj <- block[j]
  swap <- bi > bj | (bi == bj & local[i] > local[j])
  left <- ifelse(swap, j, i)
  right <- ifelse(swap, i, j)
  a <- block[left]
  b <- block[right]
  keys <- vapply(state$blocks, `[[`, character(1), "key")
  key <- paste(keys[a], keys[b], sep = ":")
  index <- ifelse(a == b,
                   (as.double(local[right]) - 1) * (local[right] - 2) / 2 +
                     local[left],
                   local[left] + (as.double(local[right]) - 1) * sizes[a])
  result <- numeric(length(i))
  groups <- split(which(i != j), key[i != j])
  for (name in names(groups)) {
    rows <- groups[[name]]
    result[rows] <- as.integer(get(name, envir = state$tiles,
                                   inherits = FALSE)[[metric]][index[rows]])
  }
  result[result == 255] <- Inf
  result
}
