# Signal an effectsurf refusal

Raises a classed condition, and no surface is returned. The class
carries `orchestra_refusal`, which is the predicate the rest of the
fleet routes on, so a caller can tell "this manifest cannot be surfaced"
from "effectsurf broke".

## Usage

``` r
effectsurf_refusal(reason, message)
```

## Arguments

- reason:

  Short machine-readable token, e.g. `"target_not_surfaceable"`.

- message:

  Human-readable explanation.

## Value

Never returns; raises a condition of class `effectsurf_refusal`,
`orchestra_refusal`, `error`, `condition`.
