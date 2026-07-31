English | [日本語](README.ja.md)

# dashboardapi

[![R-CMD-check](https://github.com/kenjimyzk/dashboardapi/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/kenjimyzk/dashboardapi/actions/workflows/R-CMD-check.yaml)

`dashboardapi` is an unofficial R package for accessing the Statistics
Dashboard Web API provided by the Statistics Bureau of Japan. The API requires
no registration or API key.

The main workflow follows the same idea as `bojapi` and `WDI`: search metadata
for an indicator code, find any needed region codes, and retrieve observations
as a tidy data frame.

## Features

- `dashboard_search()` / `dashboard_indicators()`: find indicator codes and
  inspect cycle, region, seasonal-adjustment, unit, source, and coverage
- `dashboard_regions()`: find Japanese municipality or ISO country codes
- `dashboard_data()`: retrieve normalized long or wide observations
- `dashboard_terms()`, `dashboard_events()`, and `dashboard_surveys()`: access
  the API's auxiliary metadata
- `dashboard_codes()`: inspect common API enumerations offline
- Automatic batching beyond the API limits of five indicators and 50 regions
- English and Japanese API responses, retries, timeouts, and rate-conscious
  pauses between automatically batched requests
- Typed API, HTTP, parsing, and no-data conditions

## Installation

Install the development version from GitHub:

```r
install.packages("remotes")
remotes::install_github("kenjimyzk/dashboardapi")
```

To install from a local clone of the repository:

```r
remotes::install_local(".")
```

## Quick start

```r
library(dashboardapi)

# 1. Find an indicator
population_meta <- dashboard_search(
  "Total population (Both sexes)",
  lang = "en"
)

population_meta[, c(
  "indicator_code", "name", "cycle_name",
  "regional_rank_name", "unit"
)]

# 2. Inspect region codes
prefectures <- dashboard_regions(
  parent_region_code = "00000",
  lang = "en"
)

# 3. Retrieve annual Japanese population
population <- dashboard_data(
  indicator_code = c(population = "0201010000000010000"),
  region_code = "00000",
  time_from = "2020CY00",
  time_to = "2024CY00",
  cycle = "year",
  regional_rank = "japan",
  seasonal = "original",
  lang = "en"
)
```

The `time` column preserves the API's exact period code. The `date` column
contains the first day of the represented period for analysis:
`20240100` becomes 2024-01-01, `20242Q00` becomes 2024-04-01,
`2024CY00` becomes 2024-01-01, and `2024FY00` becomes 2024-04-01.

## Prefecture example

```r
prefecture_population <- dashboard_data(
  indicator_code = c(population = "0201010000000010000"),
  region_code = c("13000", "27000"),
  time_from = "2020CY00",
  time_to = "2024CY00",
  cycle = "year",
  regional_rank = "prefecture",
  seasonal = "original",
  wide = TRUE
)
```

## Request rate and errors

The official API page asks users not to generate a large access volume in a
short period. A request with more than five indicators or 50 regions is split
automatically, and `dashboardapi` waits at least one second between those
requests.

```r
options(
  dashboardapi.wait = 2,
  dashboardapi.timeout = 60,
  dashboardapi.retries = 3
)
```

API errors have class `dashboard_api_response_error`, communication errors
have class `dashboard_http_error`, and unexpected structures have class
`dashboard_parse_error`. A successful no-data response issues a
`dashboard_no_data_warning` and returns a typed empty tibble.

## Attribution and credit for public services

The official Copyright Policy distinguishes three requirements when content
from the Statistics Dashboard is published:

1. Cite the source.
2. If content or data are edited, say so and identify the editing entity.
3. If a service uses the API, display the specified API credit.

`dashboard_api_credit()` returns the corresponding source citation,
edited-content template, and API credit. Replace `<entity>` before publishing
edited content:

```r
attribution <- dashboard_api_credit("en")
attribution$source
attribution$processed
attribution$credit
```

`dashboardapi` is independently developed and is not affiliated with or
endorsed by the Statistics Bureau of Japan. Its MIT license does not relicense
government or third-party data, metadata, code systems, or official texts.
Check any individual rights statement before reusing third-party content.

## Official documentation

- [Statistics Dashboard API](https://dashboard.e-stat.go.jp/en/static/api)
- [Statistics Dashboard site policy](https://dashboard.e-stat.go.jp/en/static/sitePolicy)
