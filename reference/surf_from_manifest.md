# Build a surface from an orchestra manifest

Places effectsurf at the end of an orchestra chain: any member emitting
an `orchestra_manifest` on a surfaceable inferential target can be
rendered without first being refitted. The manifest's `outputs` supplies
the grid.

## Usage

``` r
surf_from_manifest(
  manifest,
  x,
  y,
  estimate = NULL,
  conf_low = NULL,
  conf_high = NULL,
  type = "prediction",
  labels = list(),
  transform = NULL
)
```

## Arguments

- manifest:

  An object exposing the orchestra manifest contract –
  `inferential_target`, `outputs`, and optionally `summary` and
  `metadata`.

- x, y:

  Column names in `outputs` giving the two predictors.

- estimate:

  Column name in `outputs` giving the response. Defaults to
  `"estimate"`, falling back to `"mean"` when that is what the emitter
  used.

- conf_low, conf_high:

  Optional interval column names.

- type:

  Surface type, passed to
  [`new_effectsurf()`](https://max578.github.io/effectsurf/reference/new_effectsurf.md).

- labels, transform:

  Passed to
  [`new_effectsurf()`](https://max578.github.io/effectsurf/reference/new_effectsurf.md).

## Value

An `effectsurf` object.

## Details

The function raises a typed refusal in six cases: the object does not
present as a manifest; its `inferential_target` is not one a surface is
meaningful for; the producer already abstained (`summary$abstained`);
`outputs` is empty; no response column can be identified; or the named
columns are missing or do not form a complete rectangle, which is the
shape every downstream renderer assumes.

## See also

[`effectsurf_refusal()`](https://max578.github.io/effectsurf/reference/effectsurf_refusal.md)
