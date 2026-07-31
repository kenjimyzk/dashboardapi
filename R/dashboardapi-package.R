#' dashboardapi: Japan's Statistics Dashboard data for R
#'
#' `dashboardapi` is an unofficial, independently developed client for the
#' Statistics Dashboard Web API provided by the Statistics Bureau of Japan.
#' It is not affiliated with, endorsed by, or maintained by the Statistics
#' Bureau. A typical workflow is:
#'
#' 1. Find a series with [dashboard_search()].
#' 2. Find region codes with [dashboard_regions()].
#' 3. Retrieve observations with [dashboard_data()].
#'
#' No registration or API key is required. The API documentation asks clients
#' not to create a large volume of access in a short period. When
#' [dashboard_data()] must split a request into multiple API calls, the package
#' therefore waits at least one second between calls.
#'
#' @section Package options:
#' - `dashboardapi.lang`: default response language, `"en"` or `"jp"`.
#' - `dashboardapi.wait`: seconds between automatically batched requests;
#'   default and enforced minimum `1`.
#' - `dashboardapi.timeout`: request timeout in seconds; default `30`.
#' - `dashboardapi.retries`: retries for transient failures; default `3`.
#'
#' @section Terms of use:
#' Services published using the API should show the credit requested by the
#' Statistics Dashboard. Call [dashboard_api_credit()] for the current wording
#' copied from the official API page and for the official links. The package's
#' MIT license applies only to original package code and documentation; it does
#' not relicense government or third-party data, metadata, or official texts.
#'
#' @seealso
#' [Statistics Dashboard API](https://dashboard.e-stat.go.jp/en/static/api)
#'
#' @keywords internal
"_PACKAGE"

.dashboardapi_base_url <- "https://dashboard.e-stat.go.jp/api/1.0/Json"
.dashboardapi_max_indicators <- 5L
.dashboardapi_max_regions <- 50L

