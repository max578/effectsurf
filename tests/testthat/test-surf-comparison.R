# Tests: surf_comparison() -- estimand fidelity across backends
# ============================================================================
#
# `comparison` was never graded away from its default. Under
# `method = "emmeans"` it was dropped before it reached the helper, which
# always computed a pairwise difference, while the object's `meta` went on
# reporting the estimand that had been asked for. These tests grade the
# argument at each documented value on the backend that honours it, and
# require a refusal from the backend that does not.

# A model whose treatment effect is an exact known constant: `g` enters
# additively, so the difference b - a equals its coefficient at every point of
# the moderator grid. That constant is the oracle the surface is graded on.
fit_additive_model <- function(seed = 42L, n = 120L) {
  set.seed(seed)
  d <- data.frame(
    g  = factor(rep(c("a", "b"), length.out = n)),
    x1 = stats::runif(n, 0, 10),
    x2 = stats::runif(n, 0, 10)
  )
  d$y <- 5 + 2 * (d$g == "b") + 0.5 * d$x1 + 0.25 * d$x2 +
    stats::rnorm(n, sd = 0.1)
  stats::lm(y ~ g + x1 + x2, data = d)
}

# Fitted value for level "a" at each row of a returned surface.
baseline_prediction <- function(model, surface_data) {
  b <- stats::coef(model)
  b[["(Intercept)"]] + b[["x1"]] * surface_data$x1 + b[["x2"]] * surface_data$x2
}


# ---------------------------------------------------------------------------
# marginaleffects backend: every documented `comparison` is honoured
# ---------------------------------------------------------------------------

test_that("comparison = 'difference' returns the model's own contrast", {
  model <- fit_additive_model()
  es <- surf_comparison(model, x = "x1", y = "x2", variable = "g",
                        x_length = 4L, y_length = 4L)

  dat <- surf_data(es)
  expect_equal(dat$estimate,
               rep(stats::coef(model)[["gb"]], nrow(dat)),
               tolerance = 1e-8)
  expect_identical(es_meta(es)$meta$comparison, "difference")
})

test_that("comparison = 'ratio' returns a ratio, not a difference", {
  model <- fit_additive_model()
  es <- surf_comparison(model, x = "x1", y = "x2", variable = "g",
                        comparison = "ratio",
                        x_length = 4L, y_length = 4L)

  dat <- surf_data(es)
  pred_a <- baseline_prediction(model, dat)
  effect <- stats::coef(model)[["gb"]]

  expect_equal(dat$estimate, (pred_a + effect) / pred_a, tolerance = 1e-8)
  # The defect this file exists for: a ratio that is silently a difference.
  expect_false(isTRUE(all.equal(dat$estimate, rep(effect, nrow(dat)))))
  expect_identical(es_meta(es)$meta$comparison, "ratio")
})

test_that("comparison = 'lnratio' returns the log of the ratio", {
  model <- fit_additive_model()
  es <- surf_comparison(model, x = "x1", y = "x2", variable = "g",
                        comparison = "lnratio",
                        x_length = 4L, y_length = 4L)

  dat <- surf_data(es)
  pred_a <- baseline_prediction(model, dat)
  effect <- stats::coef(model)[["gb"]]

  expect_equal(dat$estimate, log((pred_a + effect) / pred_a), tolerance = 1e-8)
  expect_identical(es_meta(es)$meta$comparison, "lnratio")
})

test_that("a non-list contrast is honoured by the marginaleffects backend", {
  model <- fit_additive_model()
  es <- surf_comparison(model, x = "x1", y = "x2", variable = "g",
                        contrast = "reference",
                        x_length = 4L, y_length = 4L)

  dat <- surf_data(es)
  expect_equal(dat$estimate,
               rep(stats::coef(model)[["gb"]], nrow(dat)),
               tolerance = 1e-8)
  expect_identical(es_meta(es)$meta$contrast, "reference")
})


# ---------------------------------------------------------------------------
# emmeans backend: the one estimand it computes, and refusals for the rest
# ---------------------------------------------------------------------------

test_that("the emmeans backend computes a difference and says so", {
  skip_if_not_installed("emmeans")
  model <- fit_additive_model()
  es <- surf_comparison(model, x = "x1", y = "x2", variable = "g",
                        method = "emmeans",
                        x_length = 4L, y_length = 4L)

  dat <- surf_data(es)
  # emmeans's pairwise default orders the contrast a - b.
  expect_equal(abs(dat$estimate),
               rep(abs(stats::coef(model)[["gb"]]), nrow(dat)),
               tolerance = 1e-8)

  meta <- es_meta(es)$meta
  expect_identical(meta$comparison, "difference")
  # `contrast` was NULL on the way in; "pairwise" is what was applied.
  expect_identical(meta$contrast, "pairwise")
})

test_that("the emmeans backend refuses a ratio rather than returning a difference", {
  skip_if_not_installed("emmeans")
  model <- fit_additive_model()

  expect_error(
    surf_comparison(model, x = "x1", y = "x2", variable = "g",
                    comparison = "ratio", method = "emmeans",
                    x_length = 4L, y_length = 4L),
    class = "effectsurf_refusal"
  )

  cnd <- tryCatch(
    surf_comparison(model, x = "x1", y = "x2", variable = "g",
                    comparison = "ratio", method = "emmeans",
                    x_length = 4L, y_length = 4L),
    effectsurf_refusal = function(e) e
  )
  expect_true(is_effectsurf_refusal(cnd))
  expect_true(inherits(cnd, "orchestra_refusal"))
  expect_identical(cnd$reason, "estimand_unsupported_by_backend")
  expect_match(conditionMessage(cnd), "marginaleffects", fixed = TRUE)
})

test_that("the emmeans backend refuses a log-ratio", {
  skip_if_not_installed("emmeans")
  model <- fit_additive_model()
  expect_error(
    surf_comparison(model, x = "x1", y = "x2", variable = "g",
                    comparison = "lnratio", method = "emmeans",
                    x_length = 4L, y_length = 4L),
    class = "effectsurf_refusal"
  )
})

test_that("the emmeans backend refuses a contrast it would have discarded", {
  skip_if_not_installed("emmeans")
  model <- fit_additive_model()

  for (bad in list("reference", "pairwise", 1)) {
    cnd <- tryCatch(
      surf_comparison(model, x = "x1", y = "x2", variable = "g",
                      contrast = bad, method = "emmeans",
                      x_length = 4L, y_length = 4L),
      effectsurf_refusal = function(e) e
    )
    expect_true(is_effectsurf_refusal(cnd))
    expect_identical(cnd$reason, "contrast_unsupported_by_backend")
  }
})

test_that("the emmeans backend honours a list contrast and records it", {
  skip_if_not_installed("emmeans")
  model <- fit_additive_model()
  coefs <- list("b - a" = c(-1, 1))

  es <- surf_comparison(model, x = "x1", y = "x2", variable = "g",
                        contrast = coefs, method = "emmeans",
                        x_length = 4L, y_length = 4L)

  dat <- surf_data(es)
  expect_equal(dat$estimate,
               rep(stats::coef(model)[["gb"]], nrow(dat)),
               tolerance = 1e-8)

  meta <- es_meta(es)$meta
  expect_identical(meta$contrast, coefs)
  expect_identical(meta$comparison, "difference")
})


# ---------------------------------------------------------------------------
# the refusal survives the wrapper that forwards the argument
# ---------------------------------------------------------------------------

test_that("surf_sensitivity() carries the emmeans refusal through", {
  skip_if_not_installed("emmeans")
  model <- fit_additive_model()

  expect_error(
    surf_sensitivity(model, x = "x1", y = "x2", focal = "g",
                     comparison = "ratio", method = "emmeans",
                     x_length = 4L, y_length = 4L),
    class = "effectsurf_refusal"
  )

  es <- surf_sensitivity(model, x = "x1", y = "x2", focal = "g",
                         comparison = "ratio",
                         x_length = 4L, y_length = 4L)
  expect_identical(es_meta(es)$meta$comparison, "ratio")
})
