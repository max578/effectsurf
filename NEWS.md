# effectsurf (development version)

## Manifest ingress

* **`surf_from_manifest()` places effectsurf downstream of the orchestra
  contract.** Any member emitting an `orchestra_manifest` on a surfaceable
  inferential target -- `predictions`, `treatment_effects`, `breeding_values`
  -- can now be rendered without being refitted first. Previously the package
  consumed fitted model objects only and the string "manifest" did not occur
  anywhere in it, so it could not sit on a chain behind any member.

* The manifest is read duck-typed, by property name, so effectsurf takes no
  dependency on the contract package or on any member. It consumes the
  contract and emits nothing back into it, which keeps it a terminal leaf and
  makes a dependency cycle impossible.

* **`effectsurf_refusal()` gives the package its first typed abstention**,
  classed `orchestra_refusal` so the rest of the fleet can route on it.
  `surf_from_manifest()` refuses rather than degrading in six cases: the
  object does not present as a manifest, its inferential target has no
  two-predictor response, the producer already abstained, `outputs` is empty,
  the response column cannot be identified, or the grid is not a complete
  rectangle. A ragged grid previously became a surface with holes filled by
  whatever was adjacent.

## effectsurf 0.2.0.9000

* **New feature: Post-prediction surface smoothing** (`smooth` parameter).
  All `surf_*()` functions now accept a `smooth` argument that applies
  `mgcv::gam()` tensor product smoothing (`te(x, y)`) to predicted values.
  This is particularly useful for non-smooth models (random forests, boosted
  trees, MARS) where raw predictions form jagged or step-function surfaces.
  - `smooth = NULL` (default): No smoothing -- raw predictions displayed.
  - `smooth = TRUE`: Auto-smooth with `te(x, y, k = -1, bs = "tp")`,
    using `mgcv`'s automatic basis dimension selection (same default as
    `mgcv::s()`).
  - `smooth = list(k = 15, bs = "cr", smooth_ci = FALSE)`: Full manual
    control over basis dimension, basis type, and CI smoothing.
  - Separate smooth fitted per stratum when `by` is used, preserving
    interaction structure across groups.
  - Smoothing metadata stored in the effectsurf object for traceability.
* Previous version (0.1.0.9000) archived to `zz_archive/`.

## effectsurf 0.1.0.9000

* Initial development version.
* Core surface functions: `surf_prediction()`, `surf_comparison()`,
  `surf_slopes()`, `surf_cate()`.
* Interactive 3D Plotly rendering with categorical stratification.
* Confidence envelope surfaces.
* 2D profile projections via `surf_profile()`.
* Sensitivity analysis via `surf_sensitivity()`.
* Model-agnostic via `marginaleffects` (100+ model classes).
* Optional `gratia` integration for GAM smooth surfaces.
* Bundled `barley_trials` example dataset.
* HTML export via `surf_export()`.
