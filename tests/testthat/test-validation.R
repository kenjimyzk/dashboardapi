test_that("indicator and region codes are validated", {
  expect_error(
    dashboard_data("short"),
    class = "dashboard_parameter_error"
  )
  expect_error(
    dashboard_data("0201010000000010000", region_code = "Tokyo"),
    class = "dashboard_parameter_error"
  )
  expect_error(
    dashboard_indicators(indicator_code = rep("0201010000000010000", 51)),
    class = "dashboard_parameter_error"
  )
})

test_that("time and value filters are validated", {
  expect_error(
    dashboard_data(
      "0201010000000010000",
      time_from = "20240100",
      time_to = "2024CY00"
    ),
    class = "dashboard_parameter_error"
  )
  expect_error(
    dashboard_data(
      "0201010000000010000",
      value_condition = ">=100"
    ),
    class = "dashboard_parameter_error"
  )
  expect_identical(
    dashboardapi:::dash_time_code("20242Q00", "time"),
    "20242Q00"
  )
})

test_that("API errors retain a specific condition class", {
  payload <- list(
    GET_STATS = list(
      RESULT = list(
        status = "101",
        errorMsg = "IndicatorCode is mandatory input."
      )
    )
  )
  expect_error(
    dashboardapi:::dash_check_response(payload, "getData", 400L),
    class = "dashboard_api_response_error"
  )
})

test_that("unexpected response structures are parse errors", {
  expect_error(
    dashboardapi:::dash_response_root(list(other = list()), "getData"),
    class = "dashboard_parse_error"
  )
})

