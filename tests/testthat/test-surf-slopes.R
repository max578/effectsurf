
# --- emmeans backend: slope types other than dydx are refused ----------------
# emtrends() computes dy/dx only, so `slope = "eyex"` must not return dy/dx.
test_that("a slope the emmeans backend cannot compute is refused, not swapped", {
  skip_if_not_installed("emmeans")
  set.seed(1)
  d <- data.frame(a = runif(80, 1, 10), b = runif(80, 1, 10))
  d$y <- 2 * d$a + 3 * d$b + rnorm(80, sd = 0.1)
  fit <- lm(y ~ a + b, data = d)
  for (s_local in c("eyex", "eydx", "dyex")) {
    err <- tryCatch(
      surf_slopes(fit, x = "a", y = "b", variable = "a", method = "emmeans",
                  slope = s_local, x_length = 4L, y_length = 4L),
      condition = function(e) e
    )
    expect_true(is_effectsurf_refusal(err))
    expect_identical(err$reason, "slope_unsupported_by_backend")
  }
})

test_that("the default slope still runs on the emmeans backend", {
  skip_if_not_installed("emmeans")
  set.seed(1)
  d <- data.frame(a = runif(80, 1, 10), b = runif(80, 1, 10))
  d$y <- 2 * d$a + 3 * d$b + rnorm(80, sd = 0.1)
  fit <- lm(y ~ a + b, data = d)
  es <- surf_slopes(fit, x = "a", y = "b", variable = "a", method = "emmeans",
                    slope = "dydx", x_length = 4L, y_length = 4L)
  expect_true(is_effectsurf(es))
  expect_identical(es$meta$slope, "dydx")
})
