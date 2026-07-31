.dashboardapi_max_retry_after <- 60

dash_request <- function(endpoint, params, timeout) {
  url <- paste0(.dashboardapi_base_url, "/", endpoint)
  package_version <- tryCatch(
    as.character(utils::packageVersion("dashboardapi")),
    error = function(e) "development"
  )

  request <- httr2::request(url)
  request <- do.call(
    httr2::req_url_query,
    c(list(request), dash_drop_null(params))
  )
  request <- httr2::req_headers(request, `Accept-Encoding` = "gzip")
  request <- httr2::req_user_agent(
    request,
    paste0(
      "dashboardapi/", package_version,
      " (R; +https://github.com/kenjimyzk/dashboardapi)"
    )
  )
  request <- httr2::req_timeout(request, seconds = timeout)
  httr2::req_error(request, is_error = function(resp) FALSE)
}

dash_perform <- function(request) {
  httr2::req_perform(request)
}

dash_endpoint_root <- function(endpoint) {
  switch(
    endpoint,
    getIndicatorInfo = "GET_META_INDICATOR_INF",
    getRegionInfo = "GET_META_REGION_INF",
    getTermInfo = "GET_META_TERM_INFO",
    getSocialEventInfo = "GET_META_SOCIAL_INFO",
    getStatInfo = "GET_META_STAT_INFO",
    getData = "GET_STATS",
    dash_abort(
      sprintf("Unknown API endpoint: %s.", endpoint),
      class = "dashboard_internal_error"
    )
  )
}

dash_response_root <- function(payload, endpoint, http_status = NA_integer_) {
  error_class <- if (
    length(http_status) == 1L && !is.na(http_status) && http_status >= 400L
  ) {
    "dashboard_http_error"
  } else {
    "dashboard_parse_error"
  }
  if (!is.list(payload) || is.null(names(payload))) {
    dash_abort(
      "The Statistics Dashboard API response must be a JSON object.",
      class = error_class,
      endpoint = endpoint,
      http_status = http_status
    )
  }
  root_name <- dash_endpoint_root(endpoint)
  root <- payload[[root_name]]
  if (!is.list(root)) {
    dash_abort(
      sprintf("The API response does not contain `%s`.", root_name),
      class = error_class,
      endpoint = endpoint,
      http_status = http_status
    )
  }
  root
}

dash_response_status <- function(root, endpoint, http_status = NA_integer_) {
  status <- dash_field(root$RESULT, "status", default = NA_character_)
  numeric_status <- suppressWarnings(as.integer(status))
  if (is.na(numeric_status) || !status %in% c("0", "1", "101", "103", "104", "105", "106", "200", "299")) {
    dash_abort(
      "The API response contains an invalid result status.",
      class = if (
        length(http_status) == 1L && !is.na(http_status) &&
          http_status >= 400L
      ) "dashboard_http_error" else "dashboard_parse_error",
      endpoint = endpoint,
      http_status = http_status
    )
  }
  numeric_status
}

dash_check_response <- function(payload, endpoint, http_status = NA_integer_) {
  root <- dash_response_root(payload, endpoint, http_status)
  status <- dash_response_status(root, endpoint, http_status)
  if (status == 0L) {
    return(root)
  }
  if (status == 1L) {
    dash_warn_no_data()
    return(root)
  }
  message <- dash_field(root$RESULT, "errorMsg", "Unknown API error")
  dash_abort(
    sprintf("Statistics Dashboard API error %s: %s", status, message),
    class = "dashboard_api_response_error",
    status = status,
    api_message = message,
    endpoint = endpoint,
    http_status = http_status
  )
}

dash_retry_pause <- function(response, attempt, wait) {
  retry_after <- NA_real_
  if (!is.null(response)) {
    retry_after <- suppressWarnings(
      as.numeric(httr2::resp_header(response, "retry-after"))
    )
  }
  if (is.na(retry_after) || !is.finite(retry_after) || retry_after < 0) {
    retry_after <- 0
  }
  if (retry_after > .dashboardapi_max_retry_after) {
    dash_abort(
      sprintf(
        paste0(
          "The API requested a Retry-After delay of %s seconds, ",
          "exceeding the safety limit of %s seconds."
        ),
        retry_after, .dashboardapi_max_retry_after
      ),
      class = "dashboard_http_error",
      retry_after = retry_after
    )
  }
  exponential <- min(8, 2^(attempt - 1L))
  jitter <- if (wait > 0) stats::runif(1L, 0, min(0.25, wait / 4)) else 0
  dash_sleep(max(wait, retry_after, exponential) + jitter)
}

dash_fetch_json <- function(
    endpoint,
    params,
    timeout = dash_default("timeout", 30),
    retries = dash_default("retries", 3),
    wait = dash_default("wait", 1)) {
  timeout <- dash_scalar_number(timeout, "timeout", min = 0)
  retries <- dash_scalar_number(retries, "retries", min = 0, integer = TRUE)
  wait <- dash_scalar_number(wait, "wait", min = 0)
  transient_http <- c(408L, 429L, 500L, 502L, 503L, 504L)
  max_tries <- as.integer(retries) + 1L

  for (attempt in seq_len(max_tries)) {
    request <- dash_request(endpoint, params, timeout)
    result <- tryCatch(
      list(response = dash_perform(request), error = NULL),
      error = function(e) list(response = NULL, error = e)
    )
    if (!is.null(result$error)) {
      if (attempt < max_tries) {
        dash_retry_pause(NULL, attempt, wait)
        next
      }
      dash_abort(
        paste0("The Statistics Dashboard API request failed: ",
               conditionMessage(result$error)),
        class = "dashboard_http_error",
        parent = result$error,
        endpoint = endpoint
      )
    }

    response <- result$response
    http_status <- httr2::resp_status(response)
    if (http_status %in% transient_http && attempt < max_tries) {
      dash_retry_pause(response, attempt, wait)
      next
    }

    payload <- tryCatch(
      httr2::resp_body_json(
        response, check_type = FALSE, simplifyVector = FALSE
      ),
      error = function(e) {
        dash_abort(
          paste0("The API returned unreadable JSON: ", conditionMessage(e)),
          class = if (http_status >= 400L) {
            "dashboard_http_error"
          } else {
            "dashboard_parse_error"
          },
          parent = e,
          endpoint = endpoint,
          http_status = http_status
        )
      }
    )

    root <- dash_check_response(payload, endpoint, http_status)
    if (http_status >= 400L) {
      dash_abort(
        sprintf("The API returned HTTP status %s.", http_status),
        class = "dashboard_http_error",
        endpoint = endpoint,
        http_status = http_status
      )
    }
    return(root)
  }

  dash_abort(
    "The API retry loop ended unexpectedly.",
    class = "dashboard_http_error",
    endpoint = endpoint
  )
}

