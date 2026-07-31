test_that("indicator metadata become indicator-element rows", {
  out <- dashboardapi:::dash_parse_indicators(
    fixture_indicator_root(), "EN"
  )
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1L)
  expect_identical(out$indicator_code, "0201010000000010000")
  expect_identical(
    out$indicator_element_code,
    "0201010000000010000030201"
  )
  expect_identical(out$cycle_name, "Calendar Year")
  expect_identical(out$annotation, "Sample annotation.")
})

test_that("region, term, event, and survey metadata are normalized", {
  region <- dashboardapi:::dash_parse_regions(fixture_region_root(), "EN")
  expect_identical(region$region_code, "13000")
  expect_identical(region$parent_region, "Japan")

  term <- dashboardapi:::dash_parse_simple_class(
    fixture_term_root(), "getTermInfo",
    c(name = "@name", code = "@code"), "EN"
  )
  expect_identical(term$code, "0201010001")

  event <- dashboardapi:::dash_parse_events(fixture_event_root(), "EN")
  expect_identical(event$event_code, "00003")
  expect_identical(event$category_code, "0201")

  survey <- dashboardapi:::dash_parse_simple_class(
    fixture_survey_root(), "getStatInfo",
    c(stat_code = "@code", name = "@name"), "EN"
  )
  expect_identical(survey$stat_code, "20020101")
})

test_that("data responses become normalized long data", {
  aliases <- c("0201010000000010000" = "population")
  out <- dashboardapi:::dash_parse_data(fixture_data_root(), aliases)
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1L)
  expect_identical(out$indicator, "population")
  expect_identical(out$region, "Japan")
  expect_equal(out$date, as.Date("2024-01-01"))
  expect_equal(out$value, 125000000)
  expect_false(out$provisional)
  expect_identical(out$annotation, "Fixture note.")
})

test_that("non-numeric API values are retained and normalized to NA", {
  out <- dashboardapi:::dash_parse_data(fixture_data_root("***"))
  expect_true(is.na(out$value))
  expect_identical(out$value_raw, "***")
})

test_that("wide data use indicator aliases", {
  aliases <- c("0201010000000010000" = "population")
  long <- dashboardapi:::dash_parse_data(fixture_data_root(), aliases)
  wide <- dashboardapi:::dash_widen_data(long)
  expect_true("population" %in% names(wide))
  expect_equal(wide$population, 125000000)
})

test_that("API periods become dates with correct fiscal semantics", {
  period_date <- dashboardapi:::dash_period_date
  expect_equal(period_date("20240100"), as.Date("2024-01-01"))
  expect_equal(period_date("20242Q00"), as.Date("2024-04-01"))
  expect_equal(period_date("2024CY00"), as.Date("2024-01-01"))
  expect_equal(period_date("2024FY00"), as.Date("2024-04-01"))
})

test_that("no-data responses return typed empty tibbles", {
  root <- fixture_indicator_root(status = "1")
  out <- dashboardapi:::dash_parse_indicators(root, "EN")
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
  expect_type(out$indicator_code, "character")
})

