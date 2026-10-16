# Package index

## Surface Constructors

Create 3D effect surfaces from fitted models.

- [`surf_prediction()`](https://max578.github.io/effectsurf/reference/surf_prediction.md)
  : Create a 3D prediction surface
- [`surf_comparison()`](https://max578.github.io/effectsurf/reference/surf_comparison.md)
  : Create a 3D treatment effect comparison surface
- [`surf_slopes()`](https://max578.github.io/effectsurf/reference/surf_slopes.md)
  : Create a 3D marginal effect (slope) surface
- [`surf_sensitivity()`](https://max578.github.io/effectsurf/reference/surf_sensitivity.md)
  : Create a sensitivity analysis surface
- [`surf_cate()`](https://max578.github.io/effectsurf/reference/surf_cate.md)
  : Create a 3D conditional average treatment effect (CATE) surface
- [`surf_derivatives()`](https://max578.github.io/effectsurf/reference/surf_derivatives.md)
  : Compute derivative surfaces from an effectsurf object
- [`surf_grid()`](https://max578.github.io/effectsurf/reference/surf_grid.md)
  : Build a surface from a precomputed grid

## Visualisation & Export

Plot, project, and export surfaces.

- [`plot(`*`<effectsurf>`*`)`](https://max578.github.io/effectsurf/reference/plot.effectsurf.md)
  : Plot an effectsurf object as an interactive 3D surface
- [`surf_contour()`](https://max578.github.io/effectsurf/reference/surf_contour.md)
  : Create a 2D contour/heatmap from a 3D surface
- [`surf_profile()`](https://max578.github.io/effectsurf/reference/surf_profile.md)
  : Extract 2D profile slices from a 3D surface
- [`surf_export()`](https://max578.github.io/effectsurf/reference/surf_export.md)
  : Export an effectsurf plot to HTML

## Analysis

Extract data, find optima, and compare surfaces.

- [`surf_data()`](https://max578.github.io/effectsurf/reference/surf_data.md)
  : Extract data from an effectsurf object
- [`surf_optimum()`](https://max578.github.io/effectsurf/reference/surf_optimum.md)
  : Find the optimum (maximum or minimum) of a surface
- [`surf_compare()`](https://max578.github.io/effectsurf/reference/surf_compare.md)
  : Compare two surfaces side-by-side or as a difference surface
- [`surf_tidy()`](https://max578.github.io/effectsurf/reference/surf_tidy.md)
  : Convert an effectsurf object to a tidy data.frame
- [`es_meta()`](https://max578.github.io/effectsurf/reference/es_meta.md)
  : Access effectsurf metadata
- [`coef(`*`<effectsurf>`*`)`](https://max578.github.io/effectsurf/reference/coef.effectsurf.md)
  : Extract coefficients (estimates) from an effectsurf object

## Computation Layer

Lower-level grid and prediction functions.

- [`ems_grid()`](https://max578.github.io/effectsurf/reference/ems_grid.md)
  : Create a prediction grid for surface estimation
- [`ems_predict()`](https://max578.github.io/effectsurf/reference/ems_predict.md)
  : Generate predictions on a grid

## Class & Constructors

The effectsurf S3 class.

- [`new_effectsurf()`](https://max578.github.io/effectsurf/reference/new_effectsurf.md)
  : Create an effectsurf object
- [`is_effectsurf()`](https://max578.github.io/effectsurf/reference/is_effectsurf.md)
  : Check if an object is an effectsurf object
- [`effectsurf`](https://max578.github.io/effectsurf/reference/effectsurf-package.md)
  [`effectsurf-package`](https://max578.github.io/effectsurf/reference/effectsurf-package.md)
  : effectsurf: Interactive 3D Estimated Marginal Surfaces for
  Conditional Effect Visualisation

## Orchestra Contract

Build a surface from an orchestra manifest; the typed refusal returned
when one cannot be built.

- [`surf_from_manifest()`](https://max578.github.io/effectsurf/reference/surf_from_manifest.md)
  : Build a surface from an orchestra manifest
- [`effectsurf_refusal()`](https://max578.github.io/effectsurf/reference/effectsurf_refusal.md)
  : Signal an effectsurf refusal
- [`is_effectsurf_refusal()`](https://max578.github.io/effectsurf/reference/is_effectsurf_refusal.md)
  : Is this an effectsurf refusal?

## Utilities

Helper and transform functions.

- [`expit()`](https://max578.github.io/effectsurf/reference/expit.md) :
  Expit (inverse logit) function
- [`logit()`](https://max578.github.io/effectsurf/reference/logit.md) :
  Logit function
- [`label_format()`](https://max578.github.io/effectsurf/reference/label_format.md)
  : Create a label format specification

## Data

Example datasets bundled with the package.

- [`barley_trials`](https://max578.github.io/effectsurf/reference/barley_trials.md)
  : Simulated Australian Barley Agronomy Trials
