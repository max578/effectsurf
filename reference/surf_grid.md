# Build a surface from a precomputed grid

Wraps a cross-validated loss over two tuning axes, or any other grid of
values computed outside a fitted model, as an `effectsurf` object so
that
[`plot.effectsurf()`](https://max578.github.io/effectsurf/reference/plot.effectsurf.md),
[`surf_contour()`](https://max578.github.io/effectsurf/reference/surf_contour.md),
[`surf_optimum()`](https://max578.github.io/effectsurf/reference/surf_optimum.md)
and
[`surf_export()`](https://max578.github.io/effectsurf/reference/surf_export.md)
work on it. The surface is typed as a score, and print output and
default captions report it as a cross-validated score.

## Usage

``` r
surf_grid(
  data,
  x,
  y,
  z,
  conf_low = NULL,
  conf_high = NULL,
  direction = c("maximise", "minimise"),
  labels = NULL
)
```

## Arguments

- data:

  A data.frame with one row per grid cell.

- x:

  Character. Name of the column holding the first tuning axis.

- y:

  Character. Name of the column holding the second tuning axis.

- z:

  Character. Name of the column holding the score at each cell.

- conf_low, conf_high:

  Character or `NULL`. Names of columns holding a lower and upper band
  around the score; the mean minus and plus one standard error draws the
  band the one-standard-error rule reads. Both or neither must be given.

- direction:

  Character. `"maximise"` when a larger score is better, `"minimise"`
  when a smaller score is better (a loss).

- labels:

  A named list with display labels: `x`, `y`, `z`, `title`. Any element
  not given is built from the column names.

## Value

An object of class `effectsurf` with `type = "score"`, whose `z_var` is
the original name of the `z` column.

## Details

The grid must be rectangular: every combination of the distinct `x` and
`y` values present in `data` appears exactly once. A grid over the
number of variables admitted is ragged at the ends where one tuning
value admits more variables than another, and the error names each
missing cell so the grid can be restricted to the range every `y` value
reaches.

`direction` records whether larger or smaller values are better. It is
stored in `meta$direction` and read by
[`surf_optimum()`](https://max578.github.io/effectsurf/reference/surf_optimum.md)
when `type` is not given, so the optimum of a loss surface is its
minimum without further instruction.

## See also

[`new_effectsurf()`](https://max578.github.io/effectsurf/reference/new_effectsurf.md)
for the low-level constructor,
[`surf_optimum()`](https://max578.github.io/effectsurf/reference/surf_optimum.md)
for the optimum.

## Author

Max Moldovan, <max.moldovan@adelaide.edu.au>

## Examples

``` r
cv <- expand.grid(n_selected = 1:8, alpha = c(0.2, 0.4, 0.6, 0.8, 1))
cv$loss <- (cv$n_selected - 5)^2 + (cv$alpha - 0.6)^2
es <- surf_grid(cv, x = "n_selected", y = "alpha", z = "loss",
                direction = "minimise")
print(es)
#> ℹ <effectsurf> — Cross-Validated Score Surface
#> • X: n_selected | Y: alpha | Z: loss
#> • Grid: 40 points (40 per stratum)
#> • CI: FALSE | Transform: FALSE
#> • Score computed outside a model; smaller is better
#> ℹ Use `plot()` to visualise, `surf_data()` to extract data.
surf_optimum(es)
#> ℹ Surface min found:
#> • n_selected = 5
#> • alpha = 0.6
#> • estimate = 0
#>    n_selected alpha estimate
#>         <int> <num>    <num>
#> 1:          5   0.6        0
```
