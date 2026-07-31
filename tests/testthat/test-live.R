test_that("small live API requests match the documented schema", {
  skip_on_cran()
  skip_if_not(
    identical(tolower(Sys.getenv("DASHBOARDAPI_RUN_LIVE_TESTS")), "true")
  )

  indicators <- dashboard_search(
    "Total population (Both sexes)", lang = "en"
  )
  expect_s3_class(indicators, "tbl_df")
  expect_true("0201010000000010000" %in% indicators$indicator_code)

  Sys.sleep(1)
  regions <- dashboard_regions(
    parent_region_code = "00000", lang = "en"
  )
  expect_true(all(c("01000", "13000", "47000") %in% regions$region_code))

  Sys.sleep(1)
  terms <- dashboard_terms(category = "0201", lang = "en")
  expect_true("0201010001" %in% terms$code)

  Sys.sleep(1)
  events <- dashboard_events(category = "0201", lang = "en")
  expect_gt(nrow(events), 10L)
  expect_true(all(nzchar(events$event_code)))

  Sys.sleep(1)
  surveys <- dashboard_surveys(
    stat_code = "10070102", lang = "en"
  )
  expect_identical(
    surveys$stat_code,
    "10070102"
  )

  Sys.sleep(1)
  data <- dashboard_data(
    c(population = "0201010000000010000"),
    region_code = "00000",
    time_from = "2020CY00",
    time_to = "2021CY00",
    cycle = "year",
    regional_rank = "japan",
    seasonal = "original",
    lang = "en"
  )
  expect_equal(nrow(data), 2L)
  expect_identical(unique(data$indicator), "population")
  expect_true(all(is.finite(data$value)))
})
