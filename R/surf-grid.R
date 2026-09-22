# Precomputed grid constructor
# ============================================================================

#' Build a surface from a precomputed grid
#'
#' Wraps a cross-validated loss over two tuning axes, or any other grid of
#' values computed outside a fitted model, as an `effectsurf` object so that
#' [plot.effectsurf()], [surf_contour()], [surf_optimum()] and
#' [surf_export()] work on it. The surface is typed as a score, and print
#' output and default captions report it as a cross-validated score.
#'
#' @details
#' The grid must be rectangular: every combination of the distinct `x` and
#' `y` values present in `data` appears exactly once. A grid over the number
#' of variables admitted is ragged at the ends where one tuning value admits
#' more variables than another, and the error names each missing cell so the
#' grid can be restricted to the range every `y` value reaches.
#'
#' `direction` records whether larger or smaller values are better. It is
#' stored in `meta$direction` and read by [surf_optimum()] when `type` is not
#' given, so the optimum of a loss surface is its minimum without further
#' instruction.
#'
#' @param data A data.frame with one row per grid cell.
#' @param x Character. Name of the column holding the first tuning axis.
#' @param y Character. Name of the column holding the second tuning axis.
#' @param z Character. Name of the column holding the score at each cell.
#' @param conf_low,conf_high Character or `NULL`. Names of columns holding a
#'   lower and upper band around the score; the mean minus and plus one
#'   standard error draws the band the one-standard-error rule reads. Both or
#'   neither must be given.
#' @param direction Character. `"maximise"` when a larger score is better,
#'   `"minimise"` when a smaller score is better (a loss).
#' @param labels A named list with display labels: `x`, `y`, `z`, `title`.
#'   Any element not given is built from the column names.
#'
#' @returns An object of class `effectsurf` with `type = "score"`, whose
#'   `z_var` is the original name of the `z` column.
#'
#' @seealso [new_effectsurf()] for the low-level constructor,
#'   [surf_optimum()] for the optimum.
#'
#' @author Max Moldovan, \email{max.moldovan@@adelaide.edu.au}
#'
#' @examples
#' cv <- expand.grid(n_selected = 1:8, alpha = c(0.2, 0.4, 0.6, 0.8, 1))
#' cv$loss <- (cv$n_selected - 5)^2 + (cv$alpha - 0.6)^2
#' es <- surf_grid(cv, x = "n_selected", y = "alpha", z = "loss",
#'                 direction = "minimise")
#' print(es)
#' surf_optimum(es)
#'
#' @export
surf_grid <- function(
  data,
  x,
  y,
  z,
  conf_low = NULL,
  conf_high = NULL,
  direction = c("maximise", "minimise"),
  labels = NULL
) {
  direction <- match.arg(direction)
  .check_grid_columns(data, x, y, z, conf_low, conf_high)
  .check_grid_rectangular(data, x, y)

  # Rename the value columns to the names the class requires -------------
  dt <- as.data.table(data)
  data.table::setnames(dt, z, "estimate")
  has_band <- !is.null(conf_low)
  if (has_band) {
    data.table::setnames(dt, c(conf_low, conf_high), c("conf.low", "conf.high"))
  }
  keep <- c(x, y, "estimate", if (has_band) c("conf.low", "conf.high"))
  dt <- dt[, .SD, .SDcols = keep]

  new_effectsurf(
    data = dt,
    x_var = x,
    y_var = y,
    z_var = z,
    type = "score",
    ci = has_band,
    labels = if (is.null(labels)) list() else labels,
    meta = list(direction = direction)
  )
}


#' Check that the grid columns exist and the band is given as a pair
#' @noRd
.check_grid_columns <- function(data, x, y, z, conf_low, conf_high) {
  if (!is.data.frame(data)) {
    cli_abort("{.arg data} must be a data.frame or data.table.")
  }
  if (is.null(conf_low) != is.null(conf_high)) {
    cli_abort(
      "{.arg conf_low} and {.arg conf_high} must be given together or not at all."
    )
  }
  wanted <- c(x, y, z, conf_low, conf_high)
  missing_cols <- setdiff(wanted, names(data))
  if (length(missing_cols) > 0L) {
    cli_abort("Missing columns in {.arg data}: {.val {missing_cols}}.")
  }
  invisible(NULL)
}


#' Check that every (x, y) cell appears exactly once, naming the gaps
#' @noRd
.check_grid_rectangular <- function(data, x, y) {
  cells <- data.table::as.data.table(data)[, c(x, y), with = FALSE]
  if (anyDuplicated(cells) > 0L) {
    cli_abort("{.arg data} has more than one row for some {.field {x}}, {.field {y}} cells.")
  }
  full <- data.table::CJ(sort(unique(cells[[x]])), sort(unique(cells[[y]])))
  data.table::setnames(full, c(x, y))
  gaps <- full[!cells, on = c(x, y)]
  if (nrow(gaps) > 0L) {
    gap_labels <- paste0("(", gaps[[x]], ", ", gaps[[y]], ")")
    cli_abort(c(
      "{.arg data} is not a rectangular grid: {nrow(gaps)} cell{?s} of {.field {x}} by {.field {y}} {?is/are} missing.",
      "x" = "Missing: {gap_labels}."
    ))
  }
  invisible(NULL)
}
