# The manifest ingress: effectsurf's only contract seam with the orchestra.
#
# The manifest is read duck-typed, so a plain list carrying the contract's
# property names exercises the same reader a real S7 manifest does. One
# environment-conditional test below drives a genuine orchestraManifest object
# so the list stand-in is never the only oracle.

.mf <- function(target = "predictions", outputs = NULL, summary = NULL, ...) {
  c(list(inferential_target = target, outputs = outputs, summary = summary,
         emitter_package = "test", emitter_version = "0.0.0",
         run_id = "r1", method = "test:grid"), list(...))
}

.grid <- function(nx = 4L, ny = 3L) {
  g <- expand.grid(n_rate = seq_len(nx), density = seq_len(ny))
  g$estimate <- rnorm(nrow(g))
  g
}

test_that("a conformant predictions manifest becomes a surface", {
  es <- surf_from_manifest(.mf(outputs = .grid()), x = "n_rate", y = "density")
  expect_true(is_effectsurf(es))
  expect_identical(es$x_var, "n_rate")
  expect_identical(es$z_var, "estimate")
  expect_identical(es$model_info$source, "orchestra_manifest")
})

test_that("an unsurfaceable inferential target refuses typed", {
  err <- tryCatch(
    surf_from_manifest(.mf(target = "structure", outputs = .grid()),
                       x = "n_rate", y = "density"),
    condition = function(e) e
  )
  expect_true(is_effectsurf_refusal(err))
  expect_s3_class(err, "orchestra_refusal")
  expect_identical(err$reason, "target_not_surfaceable")
})

test_that("a producer's abstention is honoured, not rendered", {
  err <- tryCatch(
    surf_from_manifest(
      .mf(outputs = .grid(),
          summary = list(abstained = TRUE, abstain_reason = "no quorum")),
      x = "n_rate", y = "density"),
    condition = function(e) e
  )
  expect_true(is_effectsurf_refusal(err))
  expect_identical(err$reason, "producer_abstained")
  expect_match(conditionMessage(err), "no quorum")
})

test_that("a ragged grid refuses instead of rendering a surface with holes", {
  g <- .grid()[-1L, ]
  err <- tryCatch(
    surf_from_manifest(.mf(outputs = g), x = "n_rate", y = "density"),
    condition = function(e) e
  )
  expect_true(is_effectsurf_refusal(err))
  expect_identical(err$reason, "grid_not_rectangular")
})

test_that("an object that is not a manifest refuses typed", {
  err <- tryCatch(
    surf_from_manifest(list(a = 1), x = "n_rate", y = "density"),
    condition = function(e) e
  )
  expect_true(is_effectsurf_refusal(err))
  expect_identical(err$reason, "not_a_manifest")
})

test_that("a missing response column names the columns it did find", {
  g <- .grid(); names(g)[3] <- "yield"
  err <- tryCatch(
    surf_from_manifest(.mf(outputs = g), x = "n_rate", y = "density"),
    condition = function(e) e
  )
  expect_identical(err$reason, "estimate_not_named")
  expect_match(conditionMessage(err), "yield")
})

test_that("`mean` is accepted as the response when `estimate` is absent", {
  g <- .grid(); names(g)[3] <- "mean"
  es <- surf_from_manifest(.mf(outputs = g), x = "n_rate", y = "density")
  expect_true(is_effectsurf(es))
})

# Independent oracle: a real S7 orchestra_manifest, not a list this package
# authored. Skips cleanly where the contract package is not installed.
test_that("a genuine orchestraManifest object is accepted", {
  skip_if_not_installed("orchestraManifest")
  g <- .grid()
  m <- orchestraManifest::orchestra_manifest(
    emitter_package    = "test",
    emitter_version    = "0.0.0",
    inferential_target = "predictions",
    run_id             = "r1",
    method             = "test:grid",
    seed               = 1L,
    params             = data.frame(),
    outputs            = g,
    consumed_manifests = list(),
    metadata           = list(),
    timestamp          = Sys.time(),
    data_hash          = orchestraManifest::manifest_data_hash(
      data.frame(), g, NULL, NULL, 1L)
  )
  es <- surf_from_manifest(m, x = "n_rate", y = "density")
  expect_true(is_effectsurf(es))
  expect_identical(es$meta$manifest_target, "predictions")
})
