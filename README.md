# kinship_structure

Simulate diploid autosomal pedigree kinship and pedigree distances in a rolling
three-generation population, without genomes or sex classes. `G` counts founders: 50 generations
are labeled G0 through G49. Defaults are 5,000 generations, 500 individuals per
generation, seed 1, output root `~/scratch/kinship_structure`, and GIF playback
at 25 frames per second, showing every third generation and the final one.
Edit `DEFAULT.GIF.GENERATION.STEP <- 3L` to change the generation interval;
it must be a positive integer and has no CLI option.
Plotting detects available CPUs automatically.

## Degree-only simulation

`simulated_kinship_degrees.R` is a separate entrypoint. It calculates no kinship
coefficients and leaves `simulate_kinship.R` unchanged. Its defaults run four
independent constant-size populations (100, 1,000, 10,000, 100,000) sequentially
for 100 generations, G0–G99. Each size starts independently with seed 1.

```sh
Rscript simulated_kinship_degrees.R --generations 100 \
  --population-sizes 100,1000,10000,100000 --seed 1 \
  --output-dir ~/scratch/kinship_structure
```

Here `--population-sizes` identifies independent runs, rather than a changing
population trajectory. Named arguments use separate values as shown above.
Edit the `DEFAULT.DEGREE.*` values at the top of the new script for sourced
execution (`source("simulated_kinship_degrees.R")`). Sourcing executes the batch
and leaves `CONFIG` and `BATCH.DIR` accessible. Rendering defaults to 25 fps and
includes every generation. `make.degree.config()` accepts `block.size` and
`fps` for direct helper use; the CLI exposes only the four arguments above.
Unknown, repeated, missing and invalid arguments fail before output creation.

The two metrics are minimum path recurrences:

- **Pedigree steps:** parent–child = 1, full or half siblings = 2, full or half
  first cousins = 4. This matches the existing simulator's pedigree distances.
- **Closest-relationship degree:** parent–child and full siblings = 1, half
  siblings and grandparent–grandchild = 2, full first cousins = 3, half first
  cousins = 4. This is the specified minimum recurrence with a full-sibling
  override; it does not measure accumulated genetic relatedness or inbreeding.

Both start with unrelated founders, zero self-values and infinite unrelated
values. Child-to-existing values are one plus the minimum parental value;
distinct child-to-child values are two plus the minimum of four parental values.
The relationship metric then overrides full siblings to 1, including reversed
parent order. Old pairs never change when shared descendants appear. All
retained values survive cohort expiry, without accumulating extra routes.
Parents are uniformly sampled distinct individuals from the preceding cohort.
Only three cohorts remain active. RNG kind and seed are restored after each
helper run, and block size does not change parent sampling or numerical results.

Storage uses cohort-aligned raw-byte tiles, one byte per unordered distinct pair
per metric. Diagonal tiles store a packed triangle; rectangular tiles store each
cross-block pair once. Self-values are implicit zero, and byte 255 encodes
unrelated pairs. Finite values 1–254 support up to 128 configured generations.
Tiles are at most `block.size^2` bytes per metric (default block size 512;
maximum 4,096). Tile reads and temporary vectors are bounded by this block size.
Dropping a cohort removes its tiles; retained tiles stay in the same environment.
`advance.degree.state()` **consumes** its state: do not treat an earlier state
object as a historical snapshot, since it shares the mutable tile environment.
Save a snapshot explicitly with `saveRDS()` if needed.

At N = 100,000, 300,000 active individuals require
`2 * choose(300000, 2)` = 89,999,700,000 bytes (90.00 GB / 83.82 GiB) for both
metrics. R objects, index maps, metadata, tile lookups, temporary vectors,
serialization and rendering add overhead. Each size prints pair-memory,
temporary-block and output-storage estimates before allocating the state.
The output estimate includes uncompressed final state plus conservative text,
parent-table and figure allowances; actual usage varies. Runtime remains
quadratic in active size per generation and is **not cluster-benchmarked**.

Use a cluster allocation of **350 GB** for the large runs, with a site-specific
partition and walltime. For Slurm, request `--mem=350G` and run the command above
inside the allocation. Run increasing-size benchmarks and a short N = 100,000
pilot before launching the full batch. `/usr/bin/time -v Rscript ...` on Linux
records elapsed time and maximum resident set size; `generations.csv` also
records cumulative simulation elapsed seconds. No cluster validation or full
N = 100,000 completion is claimed by the local tests.

Every invocation creates a unique `degrees_<timestamp>_<suffix>/` batch directory
and an `N_<size>/` directory for each population. Each size writes numerical
results before rendering, and earlier batches remain intact:

| File | Contents |
| --- | --- |
| `configuration.rds`, `configuration.R`, `seed.txt` | Exact batch settings and seed |
| `parents.csv` | Every individual and its generation and parent IDs, including founders |
| `generations.csv` | G0-based labels, cohort sizes, active sizes, pair counts and elapsed seconds |
| `steps_histograms.csv`, `relationship_histograms.csv` | Generation, label, numeric degree, exact count and proportion |
| `final_state.rds` | Compact final tile environment, active metadata and index maps |
| `session_info.txt` | R/package session details and simulation RNG algorithm |

IDs are numeric, unique within a size and reused across independent populations.
Histogram denominators include every unordered distinct active pair, including
unrelated pairs, and sum to `choose(active.size, 2)`. Counts accumulate as doubles
to remain exact beyond R's integer limit. Each table completes all integer
categories through the run's largest observed finite value plus `Inf` for
**Unrelated**, including zeros at every generation.

Exactly six uncolored figures are saved per size under `figures/`, using the
existing manuscript theme, two-column facets, percentage/log1p y-axis and `+`
zero-count markers. Axes stay fixed across all generations within a size/metric.
For each prefix `steps` and `relationship`:

- `<prefix>_first10_faceted.png`: G0–G9, or every available early generation.
- `<prefix>_snapshots_faceted.png`: G0, G10, …, G90, G99 for the default run;
  shorter/longer runs use multiples of ten plus their final generation.
- `<prefix>_histogram.gif`: all generations in numeric order, with exactly 100
  frames for the default run, without interpolation or skipped generations.

For numerical-only execution or regeneration from saved summaries, load the
helpers without sourcing either entrypoint:

```r
for (helper.file in list.files("R_utils", pattern = "\\.R$",
                                full.names = TRUE)) source(helper.file)
config <- make.degree.config(generations = 4, population.sizes = c(10, 20),
                             output.dir = "tests/artifacts/degrees")
batch.dir <- run.degree.batch(config, render = FALSE)
size.dir <- file.path(batch.dir, "N_10")
saved <- list(
  config = readRDS(file.path(size.dir, "configuration.rds")),
  generations = read.csv(file.path(size.dir, "generations.csv")),
  steps = read.csv(file.path(size.dir, "steps_histograms.csv")),
  relationship = read.csv(file.path(size.dir, "relationship_histograms.csv")))
render.degree.figures(saved, file.path(size.dir, "figures_rebuilt"))
```

Rendering directly into an existing figure directory replaces matching figures;
use a fresh directory to preserve earlier renders. Figures render sequentially
so the large pair state is never copied into plotting workers.

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
`degree.histograms`, `histograms.by.cohort`, and
`degree.histograms.by.cohort` tibbles. This function alone does not write files or render plots. `make.config()` also
accepts `fps`, `gif.generation.step`, and `block.size` for interactive rendering and pair-summary
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
absolute run directory, figures directory, and all four GIF paths. In RStudio, inspect
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
| `histograms_by_cohort.csv` | Kinship histogram columns plus `cohort.pair`; proportions use all active pairs |
| `degree_histograms_by_cohort.csv` | Distance histogram columns plus `cohort.pair`; proportions use all active pairs |
| `histograms.csv` | Generation, bin index, lower/upper boundaries, right-closed flag, count and proportion |
| `figures/kinship_histogram.gif` | Every third generation plus the final generation |
| `figures/histograms_first10_faceted.png` | G0–G9 on shared axes |
| `figures/histograms_faceted.png` | All selected snapshots on shared axes |
| `figures/kinship_heatmap.png` | Generation-by-bin proportions on a shared linear color scale |
| `figures/degree_histogram.gif` | Distances every third generation plus the final generation |
| `figures/degree_histograms_first10_faceted.png` | G0–G9 distance panels on shared axes |
| `figures/degree_histograms_faceted.png` | Selected distance snapshots on shared axes |
| `figures/degree_heatmap.png` | Generation-by-distance proportions on a linear color scale |
| `figures/histograms_by_cohort_faceted.png` | Stacked cohort colors at selected kinship snapshots |
| `figures/histograms_by_cohort_first10_faceted.png` | Stacked cohort colors at G0–G9 |
| `figures/kinship_histogram_by_cohort.gif` | Cohort-colored kinship frames at the same selected generations |
| `figures/degree_histograms_by_cohort_faceted.png` | Stacked cohort colors at selected distance snapshots |
| `figures/degree_histograms_by_cohort_first10_faceted.png` | Stacked cohort colors at G0–G9 for distances |
| `figures/degree_histogram_by_cohort.gif` | Cohort-colored distance frames at the same selected generations |

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
y-axis and tick labels `0`, `5`, `10`, `15`, `20`, `25`, `50`, `75`, and `100`. The log1p transform
keeps exact-zero bins visible. Saved counts and proportions retain their
original values; percentage conversion is only applied when plotting.
Baseline `+` marks identify zero-count bins. Animation uses numerically ordered
generation factors and
[`transition_manual()`](https://gganimate.com/reference/transition_manual.html)
without interpolated generations. GIFs select
`unique(c(seq(0, G - 1, by = step), G - 1))`, always including founders and
the final generation. Each frame shows one generation without pooling. At
25 frames per second with step 3, regular steps cover 75 generations per second; the
last step can be shorter. The default has 1,668 frames ending at G4999.
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

Cohort-colored plots add four static figures and two GIFs, for ten static
figures and four GIFs total. Child, parent, and grandparent mean generation
offsets 0, 1, and 2 from the displayed generation, regardless of direct
relationships. The fixed legend and bottom-to-top stack order are:

| Pair category | Color |
| --- | --- |
| Child–child | `#0072B2` |
| Parent–parent | `#E69F00` |
| Grandparent–grandparent | `#009E73` |
| Child–parent | `#CC79A7` |
| Child–grandparent | `#D55E00` |
| Parent–grandparent | `#56B4E9` |

Each category uses all active pairs as its denominator. Summing the categories
recovers the original histogram counts and proportions in each bin. All six
categories are saved, including explicit zeros for absent cohorts at G0 and G1.
Stack boundaries are accumulated as percentages before applying log1p. A single
baseline `+` marks each wholly empty bin; zero segments within an occupied bin
have no marker. Colored plots retain the original axes, panels, and selected
frames, including Unrelated distances, with a two-row legend above the plot.
Heatmaps are unchanged.

To regenerate all figures from saved summaries without rerunning the simulation:

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
histograms.by.cohort <- read.csv(file.path(run.dir,
                                           "histograms_by_cohort.csv"))
degree.histograms.by.cohort <- read.csv(file.path(run.dir,
  "degree_histograms_by_cohort.csv"))
step <- if (is.null(config$gif.generation.step)) 3L else
  config$gif.generation.step
render.figures(histograms, generations, file.path(run.dir, "figures_rebuilt"),
                fps = config$fps, degree.histograms = degree.histograms,
                gif.generation.step = step,
                histograms.by.cohort = histograms.by.cohort,
                degree.histograms.by.cohort = degree.histograms.by.cohort)
```

The optional `degree.histograms` argument enables distance figures. The new
trailing arguments are `gif.generation.step`, `histograms.by.cohort`, and
`degree.histograms.by.cohort`. Older configurations without the step field use 3.
Older aggregate-only summaries still produce all original figures: omit the two
cohort CSV reads and grouped-summary arguments. Colored historical plots require
rerunning the simulation because aggregate tables do not retain cohort counts.
For coefficient-only regeneration, omit both distance arguments. For example:

```r
render.figures(histograms, generations, file.path(run.dir, "kinship_rebuilt"),
                fps = config$fps, gif.generation.step = step)
```

Load helpers as above; sourcing the main script executes a new run.

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
numeric frame ordering, configurable generation steps, cohort membership,
category count conservation, stacks transformed after accumulation,
reproducibility, unique output directories, CLI parity, CSV-only regeneration,
automatic CPU detection, sourced execution, repeatable PNGs, and actual
GIF/PNG rendering. Generated verification
outputs are kept under ignored `tests/artifacts/`.

Each named function lives in its own file under `R_utils/`. Simulation,
summarization, plotting and writing are separate. Slurm submission scripts and
independent simulation replicates are future additions.

Implementation verification uses small explicit configurations; the default
5,000-generation simulation is not part of the test suite.
