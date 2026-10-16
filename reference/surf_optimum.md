# Find the optimum (maximum or minimum) of a surface

Locates the combination of x and y values that maximises or minimises
the predicted response on the surface grid.

## Usage

``` r
surf_optimum(object, type = NULL)
```

## Arguments

- object:

  An
  [effectsurf](https://max578.github.io/effectsurf/reference/new_effectsurf.md)
  object.

- type:

  Character or `NULL`. `"max"` or `"min"`. When `NULL`, a surface built
  by
  [`surf_grid()`](https://max578.github.io/effectsurf/reference/surf_grid.md)
  with `direction = "minimise"` gives `"min"` and every other surface
  gives `"max"`.

## Value

A `data.table` with columns: `stratum` (if stratified), the x variable,
the y variable, `estimate`, and optionally `conf.low`, `conf.high`.

## Examples

``` r
# \donttest{
if (requireNamespace("mgcv", quietly = TRUE)) {
  model <- mgcv::gam(mpg ~ s(wt) + s(hp), data = mtcars)
  es <- surf_prediction(model, x = "wt", y = "hp",
                        x_length = 30, y_length = 30)
  surf_optimum(es, type = "max")
}
#> ℹ Surface max found:
#> • wt = 1.513
#> • hp = 52
#> • estimate = 32.6656
#>       wt    hp estimate conf.low conf.high
#>    <num> <num>    <num>    <num>     <num>
#> 1: 1.513    52 32.66558 30.33704  34.99411
# }
```
