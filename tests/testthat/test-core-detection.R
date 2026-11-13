# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# test-core-detection.R
# ______________________________________________________________________________

testthat::test_that('cluster diagnostics resolve to eight available CPUs', {
  counts <- c(system = 128L, `/proc/self/status` = 8L,
              cgroups.cpuset = 8L, nproc = 8L, Slurm = 8L)
  testthat::expect_identical(resolve.available.cores(counts), 8L)
})

testthat::test_that('CPU detection preserves tighter resource limits', {
  testthat::expect_identical(
    resolve.available.cores(c(system = 128L, nproc = 8L, Slurm = 1L)), 1L)
  testthat::expect_identical(
    resolve.available.cores(c(system = 128L, nproc = 8L, quota = 4L)), 4L)
  testthat::expect_identical(
    resolve.available.cores(c(system = 128L, nproc = 8L, missing = NA)), 8L)
  testthat::expect_identical(resolve.available.cores(c(NA, Inf, 0)), 1L)
})
