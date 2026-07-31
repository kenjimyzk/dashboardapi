test_that("public metadata functions send exact API parameter names", {
  captured <- NULL
  local_mocked_bindings(
    dash_fetch_json = function(endpoint, params, ...) {
      captured <<- list(endpoint = endpoint, params = params)
      fixture_indicator_root()
    },
    .package = "dashboardapi"
  )
  out <- dashboard_search(
    "Total population",
    cycle = "year",
    regional_rank = "japan",
    seasonal = "original"
  )
  expect_equal(nrow(out), 1L)
  expect_identical(captured$endpoint, "getIndicatorInfo")
  expect_identical(captured$params$SearchIndicatorWord, "Total population")
  expect_identical(captured$params$Cycle, "3")
  expect_identical(captured$params$RegionalRank, "2")
  expect_identical(captured$params$IsSeasonalAdjustment, "1")
})

test_that("dashboard_data batches indicators and preserves aliases", {
  calls <- list()
  local_mocked_bindings(
    dash_fetch_json = function(endpoint, params, ...) {
      calls[[length(calls) + 1L]] <<- params
      fixture_data_root()
    },
    dash_pause = function(...) invisible(NULL),
    .package = "dashboardapi"
  )
  codes <- sprintf("%019d", 1:6)
  names(codes) <- paste0("series", 1:6)
  out <- dashboard_data(codes, wait = 0)
  expect_equal(length(calls), 2L)
  expect_equal(length(strsplit(calls[[1L]]$IndicatorCode, ",")[[1L]]), 5L)
  expect_identical(calls[[1L]]$MetaGetFlg, "Y")
  expect_s3_class(out, "tbl_df")
})

test_that("credit and common code tables are available offline", {
  credit <- dashboard_api_credit("jp")
  expect_match(credit$credit, "統計ダッシュボード", fixed = TRUE)
  expect_equal(nrow(dashboard_codes("cycle")), 4L)
  expect_identical(
    dashboard_codes("seasonal", "jp")$name,
    c("原数値", "季節調整値")
  )
})

