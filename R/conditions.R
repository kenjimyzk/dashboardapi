dash_abort <- function(message, class = "dashboardapi_error", ..., call = NULL) {
  fields <- list(...)
  condition <- c(list(message = message, call = call), fields)
  class(condition) <- unique(c(
    class, "dashboardapi_error", "error", "condition"
  ))
  stop(condition)
}

dash_warn_no_data <- function() {
  condition <- structure(
    list(
      message = paste0(
        "The Statistics Dashboard API completed successfully, ",
        "but no data matched the query."
      ),
      call = NULL
    ),
    class = c(
      "dashboard_no_data_warning", "dashboardapi_warning",
      "warning", "condition"
    )
  )
  warning(condition)
}

