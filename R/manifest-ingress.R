# manifest-ingress.R -- place effectsurf downstream of the orchestra contract.
#
# effectsurf consumed fitted model objects only, so it could not sit on a chain
# behind any member that emits an `orchestra_manifest`: studies wrapped it in
# error handling with a ggplot2 fallback, which is an honest signal of how much
# the chain trusted it. This file gives it one ingress and one refusal.
#
# The manifest is read duck-typed, by property name, exactly as decideR's tail
# reads it. effectsurf therefore takes no dependency on `orchestraManifest` (or
# on any member), which keeps it a terminal leaf of the DAG: it consumes the
# contract and emits nothing back into it, so it cannot introduce a cycle.

#' Signal an effectsurf refusal
#'
#' Raises a classed condition rather than returning a degraded surface. The
#' class carries `orchestra_refusal`, which is the predicate the rest of the
#' fleet routes on, so a caller can tell "this manifest cannot be surfaced"
#' from "effectsurf broke".
#'
#' @param reason Short machine-readable token, e.g. `"target_not_surfaceable"`.
#' @param message Human-readable explanation.
#'
#' @return Never returns; raises a condition of class `effectsurf_refusal`,
#'   `orchestra_refusal`, `error`, `condition`.
#' @export
effectsurf_refusal <- function(reason, message) {
  stop(structure(
    class = c("effectsurf_refusal", "orchestra_refusal", "error", "condition"),
    list(message = message, call = NULL, reason = reason)
  ))
}

#' Is this an effectsurf refusal?
#'
#' @param x An object, typically a caught condition.
#' @return `TRUE` for a condition raised by [effectsurf_refusal()].
#' @export
is_effectsurf_refusal <- function(x) inherits(x, "effectsurf_refusal")

# Read one property from a manifest without knowing which package defined the
# class. S7 objects answer `prop_names()`; a plain list answers `names()`.
.manifest_field <- function(m, name, default = NULL) {
  if (requireNamespace("S7", quietly = TRUE) &&
      isTRUE(tryCatch(S7::S7_inherits(m), error = function(e) FALSE))) {
    if (name %in% S7::prop_names(m)) {
      return(S7::prop(m, name))
    }
    return(default)
  }
  if (is.list(m) && !is.null(m[[name]])) {
    return(m[[name]])
  }
  default
}

# The inferential targets a surface is meaningful for. A `parameters` manifest
# (an optimum, an inverted parameter set) or a `structure` manifest (a
# recovered graph) has no two-predictor response to render, and rendering one
# anyway would put a picture on a quantity that does not have this shape.
.SURFACEABLE_TARGETS <- c("predictions", "treatment_effects", "breeding_values")

#' Build a surface from an orchestra manifest
#'
#' Places effectsurf at the end of an orchestra chain: any member emitting an
#' `orchestra_manifest` on a surfaceable inferential target can be rendered
#' without first being refitted. The manifest's `outputs` supplies the grid.
#'
#' The function refuses typed rather than degrading, in four cases: the object
#' does not present as a manifest; its `inferential_target` is not one a
#' surface is meaningful for; the producer already abstained
#' (`summary$abstained`); or the named columns do not form a complete
#' rectangle, which is the shape every downstream renderer assumes.
#'
#' @param manifest An object exposing the orchestra manifest contract --
#'   `inferential_target`, `outputs`, and optionally `summary` and `metadata`.
#' @param x,y Column names in `outputs` giving the two predictors.
#' @param estimate Column name in `outputs` giving the response. Defaults to
#'   `"estimate"`, falling back to `"mean"` when that is what the emitter used.
#' @param conf_low,conf_high Optional interval column names.
#' @param type Surface type, passed to [new_effectsurf()].
#' @param labels,transform Passed to [new_effectsurf()].
#'
#' @return An `effectsurf` object.
#' @seealso [effectsurf_refusal()]
#' @export
surf_from_manifest <- function(manifest,
                               x,
                               y,
                               estimate = NULL,
                               conf_low = NULL,
                               conf_high = NULL,
                               type = "prediction",
                               labels = list(),
                               transform = NULL) {
  target <- .manifest_field(manifest, "inferential_target")
  outputs <- .manifest_field(manifest, "outputs")

  if (is.null(target) && is.null(outputs)) {
    effectsurf_refusal(
      "not_a_manifest",
      paste0("`manifest` exposes neither `inferential_target` nor `outputs`; ",
             "it does not present as an orchestra manifest")
    )
  }
  if (!is.null(target) && !as.character(target)[1L] %in% .SURFACEABLE_TARGETS) {
    effectsurf_refusal(
      "target_not_surfaceable",
      sprintf(paste0("inferential target '%s' has no two-predictor response ",
                     "to surface; surfaceable targets are %s"),
              as.character(target)[1L],
              paste(.SURFACEABLE_TARGETS, collapse = ", "))
    )
  }

  summ <- .manifest_field(manifest, "summary")
  abstained <- tryCatch(isTRUE(summ$abstained), error = function(e) FALSE)
  if (abstained) {
    reason <- tryCatch(as.character(summ$abstain_reason)[1L],
                       error = function(e) NA_character_)
    effectsurf_refusal(
      "producer_abstained",
      paste0("the producer abstained",
             if (!is.na(reason) && nzchar(reason)) paste0(": ", reason) else "",
             "; a surface would render a number the emitter declined to stand ",
             "behind")
    )
  }

  if (is.null(outputs) || !NROW(outputs)) {
    effectsurf_refusal(
      "no_outputs",
      "manifest carries no `outputs` grid to surface"
    )
  }
  outputs <- as.data.frame(outputs, stringsAsFactors = FALSE)

  if (is.null(estimate)) {
    estimate <- if ("estimate" %in% names(outputs)) {
      "estimate"
    } else if ("mean" %in% names(outputs)) {
      "mean"
    } else {
      effectsurf_refusal(
        "estimate_not_named",
        paste0("no `estimate` or `mean` column in `outputs` (columns: ",
               paste(names(outputs), collapse = ", "),
               "); name the response with `estimate=`")
      )
    }
  }

  missing <- setdiff(c(x, y, estimate), names(outputs))
  if (length(missing)) {
    effectsurf_refusal(
      "columns_absent",
      sprintf("columns %s are not in `outputs` (columns: %s)",
              paste(missing, collapse = ", "),
              paste(names(outputs), collapse = ", "))
    )
  }

  # A complete rectangle is what every renderer here assumes; a ragged grid
  # silently dcasts into a surface with holes filled by whatever happens to be
  # adjacent. Check it rather than discover it in the picture.
  nx <- length(unique(outputs[[x]]))
  ny <- length(unique(outputs[[y]]))
  if (nrow(outputs) != nx * ny) {
    effectsurf_refusal(
      "grid_not_rectangular",
      sprintf(paste0("`outputs` has %d rows but %s x %s spans %d x %d = %d ",
                     "cells; a surface needs a complete rectangle"),
              nrow(outputs), x, y, nx, ny, nx * ny)
    )
  }

  dat <- data.table::as.data.table(outputs)
  data.table::setnames(dat, estimate, "estimate")
  has_ci <- !is.null(conf_low) && !is.null(conf_high)
  if (has_ci) {
    data.table::setnames(dat, c(conf_low, conf_high),
                         c("conf.low", "conf.high"))
  }

  new_effectsurf(
    data       = dat,
    x_var      = x,
    y_var      = y,
    z_var      = "estimate",
    type       = type,
    ci         = has_ci,
    model_info = list(
      source          = "orchestra_manifest",
      emitter_package = .manifest_field(manifest, "emitter_package"),
      emitter_version = .manifest_field(manifest, "emitter_version"),
      run_id          = .manifest_field(manifest, "run_id"),
      method          = .manifest_field(manifest, "method")
    ),
    labels    = labels,
    transform = transform,
    meta      = list(
      manifest_target = if (is.null(target)) NA_character_ else
        as.character(target)[1L],
      manifest_run_id = .manifest_field(manifest, "run_id")
    )
  )
}
