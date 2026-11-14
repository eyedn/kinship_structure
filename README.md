# kinship_structure

Simulate diploid autosomal pedigree kinship and pedigree distances in a rolling
three-generation population, without genomes or sex classes. `G` counts founders: 50 generations
are labeled G0 through G49. Defaults are 5,000 generations, 500 individuals per
generation, seed 1, output root `~/scratch/kinship_structure`, and GIF playback
at 25 frames per second, showing every fifth generation and the final one.
Plotting detects available CPUs automatically.

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
`config`, `final.state` (an `individuals` tibble and aligned symmetric `kinship`
and `degree` matrices), and historical `generations`, `histograms`, and
`degree.histograms` tibbles. This function alone does not write files or render plots. `make.config()` also
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

Pedigree distance is the minimum number of parent–child steps through a common
ancestor: parent–child distance is 1, siblings (including half siblings) 2, and
first cousins 4. Self-distance is zero; founders have infinite off-diagonal
distances. A child's distance to an existing individual is one plus the minimum
of its parental distances. Distinct children's distance is two plus the minimum
of the four parental distances. Unrelated pairs remain infinite. Paths pass
upward through a common ancestor; a shared descendant never shortens an existing
pair's distance. Retained distances preserve ancestry after cohort removal.

Only final active metadata and the two final matrices are saved. Expired
individuals and earlier pairwise matrices are not archived. Final metadata can refer to
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

The script reports the combined retained numeric matrix estimate before running:
16 times the squared maximum active population size, in bytes (8 per matrix).
R matrix copies, metadata, row blocks, and rendering need additional memory. Matrix storage is
quadratic in active size, and simulation runtime scales with the sum of squared
active sizes. Historical coefficient summaries occupy 100 bins per generation;
distance summaries retain the shared integer distance categories and Unrelated.

## Saved results

Each `write.results()` call creates a unique `run_<timestamp>_<suffix>` directory
under the configured output root. Earlier runs are preserved. The default
figures location is:

```text
~/scratch/kinship_structure/run_<timestamp>_<suffix>/figures/
```

`~` expands to the home directory on the machine running R. On the cluster it
refers to your cluster home, not your local computer. The script prints the
absolute run directory, figures directory, and both GIF paths. In RStudio, inspect
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
| `final_state.rds` | Final active metadata and aligned kinship and degree matrices |
| `generations.csv` | Generation label, active cohort sizes, population and pair counts, mean kinship, mean active inbreeding, exact-zero pair count |
| `degree_histograms.csv` | Generation, label, numeric degree (`Inf` for Unrelated), count and proportion |
| `histograms.csv` | Generation, bin index, lower/upper boundaries, right-closed flag, count and proportion |
| `figures/kinship_histogram.gif` | Every fifth generation plus the final generation |
| `figures/histograms_first10_faceted.png` | G0–G9 on shared axes |
| `figures/histograms_faceted.png` | All selected snapshots on shared axes |
| `figures/kinship_heatmap.png` | Generation-by-bin proportions on a shared linear color scale |
| `figures/degree_histogram.gif` | Distances every fifth generation plus the final generation |
| `figures/degree_histograms_first10_faceted.png` | G0–G9 distance panels on shared axes |
| `figures/degree_histograms_faceted.png` | Selected distance snapshots on shared axes |
| `figures/degree_heatmap.png` | Generation-by-distance proportions on a linear color scale |

Every summary includes all unordered pairs of distinct active individuals,
within and between cohorts. The diagonal is excluded. Pair counts equal
`choose(active.size, 2)`; inbreeding means include all active individuals.

The 100 shared bins span [0,1] with width 0.01. Bins are left-closed and
right-open, except the final bin includes 1. Zero-count bins are retained;
`zero.count` separately counts coefficients exactly equal to zero. Proportions
use each generation's total active pair count.

Distance categories span every integer from 1 through the run's maximum observed
finite distance, followed by **Unrelated**. Every generation retains zero-count
categories. For a founders-only run, the only category is Unrelated. Proportions
include all active pairs in the denominator, including unrelated pairs.

Histogram axes stay fixed across generations. All histogram PNGs and GIF
frames plot `percentage = 100 * proportion` with a `log(1 + percentage)`
y-axis and tick labels `0`, `25`, `50`, `75`, and `100`. The log1p transform
keeps exact-zero bins visible. Saved counts and proportions retain their
original values; percentage conversion is only applied when plotting.
Baseline `+` marks identify zero-count bins. Animation uses numerically ordered
generation factors and
[`transition_manual()`](https://gganimate.com/reference/transition_manual.html)
without interpolated generations. GIFs select
`unique(c(seq(0, G - 1, by = 5), G - 1))`, always including founders and
the final generation. Each frame shows one generation without pooling. At
25 frames per second, regular steps cover 125 generations per second; the
last step can be shorter. The default has 1,001 frames ending at G4999.
Overview snapshots select
`unique(round(seq(0, G - 1, length.out = 6)))`, or every generation when G < 6.
The defaults select G0, G1000, G2000, G2999, G3999, and G4999. Heatmaps place
later generations higher on the y-axis. Both heatmaps use equally spaced
blue, cyan, green, yellow, orange, and red colors on a continuous linear scale
from zero to the maximum proportion, with blue low and red high. The horizontal
color bar above each plot labels proportions. GIFs use `gganimate::magick_renderer()` and are saved with
`magick::image_write()`; `gifski` is not required.

Both metrics use a shared local manuscript theme: `theme_bw(base_size = 24)`,
plain facet labels, blank strip backgrounds, no minor gridlines, and horizontal
legends above plots. Overview faceted figures use two columns and up to three
rows. The first-ten figures show G0–G9 in two columns and five rows; shorter
runs show all available generations with adjusted height. Both named faceted
figures are produced even when their selections coincide. Cohort-size labels
wrap for readability. `RENDER.INFO` retains `snapshots` and also returns
`early.snapshots` and `animation.generations`.

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
degree.histograms <- read.csv(file.path(run.dir, "degree_histograms.csv"))
render.figures(histograms, generations, file.path(run.dir, "figures_rebuilt"),
                fps = config$fps, degree.histograms = degree.histograms)
```

The optional trailing `degree.histograms` argument enables both metrics. Omit
it to regenerate coefficient-only figures, including runs saved before distances
were added. Load helpers as above; sourcing the main script executes a new run.

Rendering to an existing figure directory replaces matching figure files.
Individual `histogram_G*.png` and `degree_histogram_G*.png` files are no longer
generated. Historical files, including these individual PNGs, are preserved in
reused directories. Use a new directory to preserve all earlier renderings.

## Verification

```sh
Rscript tests/testthat.R
```

Tests cover known pedigrees, an independent scalar full-pedigree reference
through cohort removal, full-ancestor distance references, unrelated co-parents,
inbreeding, matrix invariants, changing population sizes, histogram
boundaries and exact zeros, G=1/G=2/G=6/G=50/G=5000 snapshot endpoints,
numeric frame ordering,
reproducibility, unique output directories, CLI parity, CSV-only regeneration,
automatic CPU detection, sourced execution, repeatable PNGs, and actual
GIF/PNG rendering. Generated verification
outputs are kept under ignored `tests/artifacts/`.

Each named function lives in its own file under `R_utils/`. Simulation,
summarization, plotting and writing are separate. Slurm submission scripts and
independent simulation replicates are future additions.

Implementation verification uses small explicit configurations; the default
5,000-generation simulation is not part of the test suite.
