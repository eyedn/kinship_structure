# kinship_structure

Simulate diploid autosomal pedigree kinship in a rolling three-generation
population, without genomes or sex classes. `G` counts founders: 50 generations
are labeled G0 through G49. Defaults are 100 generations, 100 individuals per
generation, seed 1, output root `~/scratch/kinship_structure`, and GIF playback
at five generations per second. Plotting detects available CPUs automatically.

## Run

Install the R dependencies once:

```r
install.packages(c("tibble", "dplyr", "ggplot2", "future", "furrr",
                   "gganimate", "magick", "testthat", "png"))
```

Run with defaults, or pass named arguments using spaces or `=`:

```sh
Rscript simulate_kinship.R
Rscript simulate_kinship.R --generations 4 --population-sizes 100,80,120,100 \
  --seed 1 --output-dir ~/scratch/kinship_structure
```

`--population-sizes` must contain exactly `G` comma-separated integers, all at
least two, beginning at G0. When omitted, every generation uses
`DEFAULT.POPULATION.SIZE`. Generations must be a positive integer; seed must
be a nonnegative integer. There is no worker parameter or `--workers` option.
Unknown, duplicate, missing, or invalid arguments fail before simulation. Execution never waits for stdin.

Edit the uppercase defaults at the top of `simulate_kinship.R`. The script can
be run from any working directory; relative output paths use that directory.

For interactive execution in RStudio, set the working directory to this
project, edit the defaults, and click **Source**, or run:

```r
source("simulate_kinship.R")
FIGURES.DIR
list.files(FIGURES.DIR, full.names = TRUE)
print(plot.heatmap(RESULT$histograms))
```

Sourcing runs the complete simulation, saves results, and renders figures.
The top-level workflow has no `if` guard, `tryCatch`, or `quit()` call: errors
stop at the failing line and leave existing objects accessible in RStudio.
`CONFIG`, `RESULT`, `RUN.DIR`, `FIGURES.DIR`, and `RENDER.INFO` remain available
for inspection. Run selections from the top so defaults and helpers are loaded.

`run.simulation(CONFIG)` remains available for manual reruns. It returns
`config`, `final.state` (an `individuals` tibble and a symmetric `kinship`
matrix), and the historical `generations` and `histograms` tibbles. This
function alone does not write files or render plots. `make.config()` also
accepts `fps` and `block.size` for interactive rendering and pair-summary
row blocks.

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
counts do not affect simulation results. Each rendering call detects available
CPUs using `future::availableCores(which = "all")`, then selects the smallest
valid positive count across detection methods. For example, system=128 with
process affinity, cgroups, nproc and Slurm all reporting 8 resolves to 8. Every
render prints the per-method counts and detected CPU count; these are also
returned as `RENDER.INFO$core.counts` and `RENDER.INFO$available.cores`.
Independent static plots use `future`/`furrr`, with workers
limited to the smaller of available CPUs and the number of static plots. The
caller's future plan is restored afterward. Population updates and GIF frames
remain sequential.

The script reports the largest retained numeric matrix estimate before running:
8 times the squared maximum active population size, in bytes. R matrix copies,
metadata, row blocks, and rendering need additional memory. Matrix storage is
quadratic in active size, and simulation runtime scales with the sum of squared
active sizes. Historical summaries occupy 100 bins per generation.

## Saved results

Each `write.results()` call creates a unique `run_<timestamp>_<suffix>` directory
under the configured output root. Earlier runs are preserved. The default
figures location is:

```text
~/scratch/kinship_structure/run_<timestamp>_<suffix>/figures/
```

`~` expands to the home directory on the machine running R. On the cluster it
refers to your cluster home, not your local computer. The script prints the
absolute run directory, figures directory, and GIF path. In RStudio, inspect
`FIGURES.DIR` or use the Files pane to open that path.

Both CLI and sourced execution write numerical results before rendering. Those
results remain available if rendering fails. The `figures/` directory is created
when rendering starts; it is absent if only `run.simulation()` or
`write.results()` has been called.

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

Histogram axes stay fixed across generations. All histogram PNGs and GIF
frames use a base-10 pseudo-log y-axis (`sigma = 0.001`) with labels
`0`, `.25`, `.5`, `.75`, and `1`. This expands small proportions and transitions
smoothly to a linear scale near zero, so exact-zero bins remain visible.
Saved counts and proportions retain their original values. Baseline `+` marks
identify zero-count bins. Animation uses numerically ordered generation factors and
[`transition_manual()`](https://gganimate.com/reference/transition_manual.html)
without interpolated generations. Snapshots select unique valid generations
from G0-G5, Gfloor(G/2), and G(G-1). The heatmap places later generations higher
on the y-axis. GIFs use `gganimate::magick_renderer()` and are saved with
`magick::image_write()`; `gifski` is not required.

To regenerate figures from saved summaries without rerunning the simulation:

```r
for (helper.file in list.files("R_utils", pattern = "\\.R$",
                                full.names = TRUE)) {
  source(helper.file)
}
run.dir <- path.expand("~/scratch/kinship_structure/run_<timestamp>_<suffix>")
histograms <- read.csv(file.path(run.dir, "histograms.csv"))
generations <- read.csv(file.path(run.dir, "generations.csv"))
config <- readRDS(file.path(run.dir, "configuration.rds"))
render.figures(histograms, generations, file.path(run.dir, "figures_rebuilt"),
                fps = config$fps)
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
automatic CPU detection, sourced execution, repeatable PNGs, and actual
GIF/PNG rendering. Generated verification
outputs are kept under ignored `tests/artifacts/`.

Each named function lives in its own file under `R_utils/`. Simulation,
summarization, plotting and writing are separate. Slurm submission scripts and
independent simulation replicates are future additions.
