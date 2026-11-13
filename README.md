# kinship_structure

Simulate diploid autosomal pedigree kinship in a rolling three-generation
population, without genomes or sex classes. `G` counts founders: 50 generations
are labeled G0 through G49. Defaults are 100 generations, 100 individuals per
generation, seed 1, one plotting worker, and GIF playback at five generations
per second.

## Run

Install the R dependencies once:

```r
install.packages(c("tibble", "dplyr", "ggplot2", "future", "furrr",
                   "gganimate", "gifski", "testthat", "png"))
```

Run with defaults, or pass named arguments using spaces or `=`:

```sh
Rscript simulate_kinship.R
Rscript simulate_kinship.R --generations 4 --population-sizes 100,80,120,100 \
  --seed 1 --workers 2 --output-dir outputs
```

`--population-sizes` must contain exactly `G` comma-separated integers, all at
least two, beginning at G0. When omitted, every generation uses
`DEFAULT.POPULATION.SIZE`. Generations and workers must be positive integers;
seed must be a nonnegative integer. Unknown, duplicate, missing, or invalid
arguments fail before simulation. Execution never waits for stdin.

Edit the uppercase defaults at the top of `simulate_kinship.R`. The script can
be run from any working directory; relative output paths use that directory.

For interactive execution:

```r
source("simulate_kinship.R")
config <- make.config(generations = 50,
                      population.sizes = rep(100L, 50), seed = 1)
result <- run.simulation(config)
run.dir <- write.results(result)
render.figures(result$histograms, result$generations,
                file.path(run.dir, "figures"), workers = config$workers,
                fps = config$fps)
```

Sourcing only defines defaults and functions. `run.simulation()` returns
`config`, `final.state` (an `individuals` tibble and a symmetric `kinship`
matrix), and the historical `generations` and `histograms` tibbles. It does not
write files or render plots. `make.config()` also accepts `fps` and `block.size`
for interactive rendering and pair-summary row blocks.

## Model and storage

Founders are unrelated, with inbreeding zero and self-kinship 0.5. Each child
samples two distinct parents uniformly from the immediately preceding cohort.
Parents can have multiple children, and related parents may mate.

For parents p and q, a child's inbreeding is K[p,q]. Its kinship to an existing
individual j is (K[p,j] + K[q,j])/2. For distinct children, kinship is the average
of the four parental kinships. Self-kinship is (1 + inbreeding)/2. These are the
standard [pedigree kinship recursions](https://cloud.r-project.org/web/packages/kinship2/vignettes/kinship_code_details.html).

At generation t the active population contains max(0,t-2) through t. The oldest
cohort is removed before adding a fourth. Retained coefficients preserve
ancestral relatedness after ancestors leave the active population. Individual
IDs are unique, and matrix row and column names match metadata order.

Only final active metadata and the final matrix are saved. Expired individuals
and earlier pairwise matrices are not archived. Final metadata can refer to
expired parent IDs; it is not a full pedigree archive.

Parent assignments and generation updates run sequentially. The simulation
sets a fixed RNG algorithm and restores the caller's RNG state. Plotting worker
counts do not affect simulation results. Independent static plots can use
`future`/`furrr`; workers are capped by available CPUs, and the caller's future
plan is restored afterward.

The script reports the largest retained numeric matrix estimate before running:
8 times the squared maximum active population size, in bytes. R matrix copies,
metadata, row blocks, and rendering need additional memory. Matrix storage is
quadratic in active size, and simulation runtime scales with the sum of squared
active sizes. Historical summaries occupy 100 bins per generation.

## Saved results

Each `write.results()` call creates a unique `run_<timestamp>_<suffix>` directory
under the configured output root. Earlier runs are preserved. CLI execution
writes numerical results before rendering, so those results remain available
if rendering fails.

| File | Contents |
| --- | --- |
| `configuration.rds`, `configuration.R` | Exact configuration in binary and readable R forms |
| `seed.txt` | Simulation seed |
| `package_versions.csv`, `session_info.txt` | Package versions, R session and simulation RNG algorithm |
| `final_state.rds` | Final active metadata and aligned kinship matrix |
| `generations.csv` | Generation label, active cohort sizes, population and pair counts, mean kinship, mean active inbreeding, exact-zero pair count |
| `histograms.csv` | Generation, bin index, lower/upper boundaries, right-closed flag, count and proportion |
| `figures/kinship_histogram.gif` | One discrete frame per generation |
| `figures/histogram_G*.png` | Selected generation snapshots |
| `figures/histograms_faceted.png` | All selected snapshots on shared axes |
| `figures/kinship_heatmap.png` | Generation-by-bin proportions on a shared linear color scale |

Every summary includes all unordered pairs of distinct active individuals,
within and between cohorts. The diagonal is excluded. Pair counts equal
`choose(active.size, 2)`; inbreeding means include all active individuals.

The 100 shared bins span [0,1] with width 0.01. Bins are left-closed and
right-open, except the final bin includes 1. Zero-count bins are retained;
`zero.count` separately counts coefficients exactly equal to zero. Proportions
use each generation's total active pair count.

Histogram axes stay fixed across generations. Baseline `+` marks identify
zero-count bins. Animation uses numerically ordered generation factors and
[`transition_manual()`](https://gganimate.com/reference/transition_manual.html)
without interpolated generations. Snapshots select unique valid generations
from G0-G5, Gfloor(G/2), and G(G-1). The heatmap places later generations higher
on the y-axis.

To regenerate figures from saved summaries without rerunning the simulation:

```r
source("simulate_kinship.R")
run.dir <- "outputs/run_<timestamp>_<suffix>"
histograms <- read.csv(file.path(run.dir, "histograms.csv"))
generations <- read.csv(file.path(run.dir, "generations.csv"))
config <- readRDS(file.path(run.dir, "configuration.rds"))
render.figures(histograms, generations, file.path(run.dir, "figures_rebuilt"),
                workers = config$workers, fps = config$fps)
```

Rendering to an existing figure directory replaces matching figure files. Use
a new directory when preserving an earlier rendering.

## Verification

```sh
Rscript tests/testthat.R
```

Tests cover known pedigrees, an independent scalar full-pedigree reference
through cohort removal, matrix invariants, changing population sizes, histogram
boundaries and exact zeros, G=1/G=2/G=50 endpoints, numeric frame ordering,
reproducibility, unique output directories, CLI parity, CSV-only regeneration,
worker-independent PNGs, and actual GIF/PNG rendering. Generated verification
outputs are kept under ignored `tests/artifacts/`.

Each named function lives in its own file under `R_utils/`. Simulation,
summarization, plotting and writing are separate. Slurm submission scripts and
independent simulation replicates are future additions.
