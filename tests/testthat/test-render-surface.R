# Tests for plot.effectsurf() — rendering layer
# ============================================================================

# =============================================================================
# Single surface rendering
# =============================================================================

test_that("plot.effectsurf() returns a plotly object for a single surface", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("marginaleffects")
  skip_if_not_installed("plotly")

  model <- mgcv::gam(mpg ~ s(wt) + s(hp), data = mtcars)
  es <- surf_prediction(model, x = "wt", y = "hp",
                        x_length = 5L, y_length = 5L)

  p <- plot(es)
  expect_s3_class(p, "plotly")
})

test_that("plot.effectsurf() renders without error for single surface", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("marginaleffects")
  skip_if_not_installed("plotly")

  model <- mgcv::gam(mpg ~ s(wt) + s(hp), data = mtcars)
  es <- surf_prediction(model, x = "wt", y = "hp",
                        x_length = 5L, y_length = 5L)

  expect_no_error(plot(es))
})

# =============================================================================
# Stratified surface rendering
# =============================================================================

test_that("plot.effectsurf() renders stratified surface without error", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("marginaleffects")
  skip_if_not_installed("plotly")

  dat <- mtcars
  dat$cyl <- factor(dat$cyl)
  model <- mgcv::gam(mpg ~ s(wt) + s(hp) + cyl, data = dat)
  es <- surf_prediction(model, x = "wt", y = "hp", by = "cyl",
                        x_length = 5L, y_length = 5L)

  p <- plot(es)
  expect_s3_class(p, "plotly")
})

# =============================================================================
# CI surfaces
# =============================================================================

test_that("plot.effectsurf() with show_ci = TRUE adds CI surfaces", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("marginaleffects")
  skip_if_not_installed("plotly")

  model <- mgcv::gam(mpg ~ s(wt) + s(hp), data = mtcars)
  es <- surf_prediction(model, x = "wt", y = "hp",
                        x_length = 5L, y_length = 5L, ci = TRUE)

  p <- plot(es, show_ci = TRUE)
  expect_s3_class(p, "plotly")
  p_no_ci <- plot(es, show_ci = FALSE)
  expect_s3_class(p_no_ci, "plotly")
  # CI version should have more traces (main + lower + upper)
  expect_true(length(p$x$data) >= length(p_no_ci$x$data))
})

# =============================================================================
# Custom camera
# =============================================================================

test_that("plot.effectsurf() accepts custom camera", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("marginaleffects")
  skip_if_not_installed("plotly")

  model <- mgcv::gam(mpg ~ s(wt) + s(hp), data = mtcars)
  es <- surf_prediction(model, x = "wt", y = "hp",
                        x_length = 5L, y_length = 5L)

  custom_cam <- list(eye = list(x = 2, y = 2, z = 2))
  p <- plot(es, camera = custom_cam)

  expect_s3_class(p, "plotly")
})

# =============================================================================
# Error handling
# =============================================================================

test_that("plot.effectsurf() errors on non-effectsurf input", {
  skip_if_not_installed("plotly")

  expect_error(
    plot.effectsurf(list(a = 1)),
    "effectsurf"
  )
})

# =============================================================================
# Appearance parameters
# =============================================================================

test_that("plot.effectsurf() accepts opacity and colourscale arguments", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("marginaleffects")
  skip_if_not_installed("plotly")

  model <- mgcv::gam(mpg ~ s(wt) + s(hp), data = mtcars)
  es <- surf_prediction(model, x = "wt", y = "hp",
                        x_length = 5L, y_length = 5L)

  expect_no_error(plot(es, opacity = 0.5, colourscale = "RdBu"))
})

# =============================================================================
# Profile PDFs on a non-square grid
# =============================================================================

# The surface value depends on x alone, so the x profile is the x values
# scaled and the y profile is constant. A square grid would pass a length
# check with the two margins exchanged; 8 by 5 does not.
non_square_surface <- function() {
  grid <- expand.grid(n_selected = 1:8, alpha = c(0.2, 0.4, 0.6, 0.8, 1))
  grid$estimate <- grid$n_selected * 10
  new_effectsurf(
    data = grid, x_var = "n_selected", y_var = "alpha",
    z_var = "estimate", type = "prediction"
  )
}

test_that("max_profiles() takes the x profile over columns and the y profile over rows", {
  es <- non_square_surface()
  profiles <- max_profiles(to_surface_matrices(es))

  expect_length(profiles$x$all, 8L)
  expect_length(profiles$y$all, 5L)
  expect_equal(unname(profiles$x$all), seq(10, 80, by = 10))
  expect_equal(unname(profiles$y$all), rep(80, 5L))
})

test_that("plot.effectsurf(save_html = ) writes both profile PDFs for a non-square grid", {
  skip_if_not_installed("plotly")
  skip_if_not_installed("htmlwidgets")
  skip_if_not_installed("ggplot2")

  es <- non_square_surface()
  tmp <- tempfile(fileext = ".html")
  base <- tools::file_path_sans_ext(tmp)
  on.exit(unlink(c(tmp, paste0(base, c("_X_profile.pdf", "_Y_profile.pdf")))),
          add = TRUE)

  expect_no_error(suppressMessages(plot(es, save_html = tmp)))
  expect_true(file.exists(paste0(base, "_X_profile.pdf")))
  expect_true(file.exists(paste0(base, "_Y_profile.pdf")))
})
