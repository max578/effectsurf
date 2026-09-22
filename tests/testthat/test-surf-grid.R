# Tests for surf_grid() — precomputed grid constructor
# ============================================================================

# An 8 by 5 loss grid with its minimum at (5, 0.6).
cv_grid <- function() {
  grid <- expand.grid(n_selected = 1:8, alpha = c(0.2, 0.4, 0.6, 0.8, 1))
  grid$loss <- (grid$n_selected - 5)^2 + (grid$alpha - 0.6)^2
  grid$lo <- grid$loss - 0.1
  grid$hi <- grid$loss + 0.1
  grid
}

# =============================================================================
# Construction
# =============================================================================

test_that("surf_grid() builds a score surface from a rectangular grid", {
  es <- surf_grid(cv_grid(), x = "n_selected", y = "alpha", z = "loss",
                  direction = "minimise")

  expect_s3_class(es, "effectsurf")
  expect_identical(es$type, "score")
  expect_identical(es$z_var, "loss")
  expect_identical(es$meta$direction, "minimise")
  expect_true("estimate" %in% names(es$data))
  expect_false("loss" %in% names(es$data))
  expect_equal(nrow(es$data), 40L)
  expect_false(es$ci)
  expect_match(es$labels$title, "Cross-validated score surface")
})

test_that("surf_grid() carries a band when both bounds are named", {
  es <- surf_grid(cv_grid(), x = "n_selected", y = "alpha", z = "loss",
                  conf_low = "lo", conf_high = "hi")

  expect_true(es$ci)
  expect_true(all(c("conf.low", "conf.high") %in% names(es$data)))
  expect_identical(es$meta$direction, "maximise")
})

test_that("surf_grid() refuses one bound without the other", {
  expect_error(
    surf_grid(cv_grid(), x = "n_selected", y = "alpha", z = "loss",
              conf_low = "lo"),
    "together"
  )
})

test_that("surf_grid() names a missing column", {
  expect_error(
    surf_grid(cv_grid(), x = "n_selected", y = "alpha", z = "rmse"),
    "rmse"
  )
})

test_that("print() reports a score surface and its direction", {
  es <- surf_grid(cv_grid(), x = "n_selected", y = "alpha", z = "loss",
                  direction = "minimise")
  out <- capture.output(print(es), type = "message")

  expect_true(any(grepl("Cross-Validated Score Surface", out)))
  expect_true(any(grepl("smaller is better", out)))
})

# =============================================================================
# Rectangularity
# =============================================================================

test_that("surf_grid() errors on a ragged grid and names the missing cells", {
  grid <- cv_grid()
  ragged <- grid[!(grid$n_selected == 8 & grid$alpha %in% c(0.2, 0.4)), ]

  expect_error(
    surf_grid(ragged, x = "n_selected", y = "alpha", z = "loss"),
    "\\(8, 0.2\\)"
  )
  expect_error(
    surf_grid(ragged, x = "n_selected", y = "alpha", z = "loss"),
    "\\(8, 0.4\\)"
  )
  expect_error(
    surf_grid(ragged, x = "n_selected", y = "alpha", z = "loss"),
    "2 cells"
  )
})

test_that("surf_grid() errors on a duplicated cell", {
  grid <- cv_grid()
  doubled <- rbind(grid, grid[1L, ])

  expect_error(
    surf_grid(doubled, x = "n_selected", y = "alpha", z = "loss"),
    "more than one row"
  )
})

# =============================================================================
# Downstream verbs
# =============================================================================

test_that("surf_optimum() defaults to the minimum under direction = 'minimise'", {
  es <- surf_grid(cv_grid(), x = "n_selected", y = "alpha", z = "loss",
                  direction = "minimise")
  opt <- suppressMessages(surf_optimum(es))

  expect_equal(opt$n_selected, 5L)
  expect_equal(opt$alpha, 0.6)
  expect_equal(opt$estimate, 0)

  opt_max <- suppressMessages(surf_optimum(es, type = "max"))
  expect_equal(opt_max$estimate, max(cv_grid()$loss))
})

test_that("surf_optimum() still defaults to the maximum for a model surface", {
  grid <- cv_grid()
  es <- new_effectsurf(
    data = data.table::setnames(data.table::as.data.table(grid), "loss", "estimate"),
    x_var = "n_selected", y_var = "alpha", z_var = "estimate",
    type = "prediction"
  )
  opt <- suppressMessages(surf_optimum(es))

  expect_equal(opt$estimate, max(grid$loss))
})

test_that("surf_contour(interactive = TRUE) runs on a non-square score grid", {
  skip_if_not_installed("plotly")

  es <- surf_grid(cv_grid(), x = "n_selected", y = "alpha", z = "loss",
                  direction = "minimise")
  p <- surf_contour(es, interactive = TRUE)

  expect_s3_class(p, "plotly")
})

test_that("surf_export() runs on a non-square score grid", {
  skip_if_not_installed("plotly")
  skip_if_not_installed("htmlwidgets")

  es <- surf_grid(cv_grid(), x = "n_selected", y = "alpha", z = "loss",
                  direction = "minimise")
  tmp <- tempfile(fileext = ".html")
  base <- tools::file_path_sans_ext(tmp)
  on.exit(unlink(c(tmp, paste0(base, c("_X_profile.pdf", "_Y_profile.pdf")))),
          add = TRUE)

  expect_no_error(suppressMessages(
    surf_export(es, path = tmp, selfcontained = FALSE)
  ))
  expect_true(file.exists(tmp))
})
