`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

dash_default <- function(option, default) {
  getOption(paste0("dashboardapi.", option), default)
}

dash_scalar_character <- function(x, arg, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(NULL)
  }
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    dash_abort(
      sprintf("`%s` must be one non-empty character value.", arg),
      class = "dashboard_parameter_error"
    )
  }
  x
}

dash_scalar_number <- function(x, arg, min = -Inf, integer = FALSE) {
  if (
    !is.numeric(x) || length(x) != 1L || is.na(x) ||
      !is.finite(x) || x < min
  ) {
    dash_abort(
      sprintf(
        "`%s` must be one number greater than or equal to %s.",
        arg, min
      ),
      class = "dashboard_parameter_error"
    )
  }
  if (integer && x != floor(x)) {
    dash_abort(
      sprintf("`%s` must be a whole number.", arg),
      class = "dashboard_parameter_error"
    )
  }
  x
}

dash_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    dash_abort(
      sprintf("`%s` must be TRUE or FALSE.", arg),
      class = "dashboard_parameter_error"
    )
  }
  x
}

dash_match_lang <- function(lang = dash_default("lang", "en")) {
  if (is.null(lang)) {
    lang <- "en"
  }
  lang <- tolower(dash_scalar_character(lang, "lang"))
  if (!lang %in% c("en", "jp")) {
    dash_abort(
      "`lang` must be either \"en\" or \"jp\".",
      class = "dashboard_parameter_error"
    )
  }
  toupper(lang)
}

dash_optional_character <- function(x, arg) {
  if (is.null(x)) {
    return(NULL)
  }
  dash_scalar_character(x, arg)
}

dash_character_vector <- function(
    x,
    arg,
    max = Inf,
    pattern = NULL,
    allow_null = TRUE) {
  if (is.null(x) && allow_null) {
    return(NULL)
  }
  if (
    !is.character(x) || length(x) < 1L || anyNA(x) ||
      any(!nzchar(x))
  ) {
    dash_abort(
      sprintf("`%s` must be a non-empty character vector.", arg),
      class = "dashboard_parameter_error"
    )
  }
  if (length(x) > max) {
    dash_abort(
      sprintf("`%s` may contain at most %s values.", arg, max),
      class = "dashboard_parameter_error"
    )
  }
  if (!is.null(pattern) && any(!grepl(pattern, unname(x)))) {
    dash_abort(
      sprintf("`%s` contains an invalid code.", arg),
      class = "dashboard_parameter_error"
    )
  }
  unname(x)
}

dash_indicator_codes <- function(x, max = Inf) {
  dash_character_vector(
    x, "indicator_code", max = max, pattern = "^[0-9]{19}$",
    allow_null = FALSE
  )
}

dash_region_codes <- function(x, max = Inf, allow_null = TRUE) {
  dash_character_vector(
    x, "region_code", max = max, pattern = "^([0-9]{5}|[A-Z]{3})$",
    allow_null = allow_null
  )
}

dash_join <- function(x) {
  if (is.null(x)) NULL else paste(x, collapse = ",")
}

dash_chunks <- function(x, size) {
  if (is.null(x)) {
    return(list(NULL))
  }
  split(x, ceiling(seq_along(x) / size))
}

dash_choice_code <- function(x, arg, choices, allow_null = TRUE) {
  if (is.null(x) && allow_null) {
    return(NULL)
  }
  if (is.numeric(x) && length(x) == 1L && !is.na(x)) {
    x <- as.character(x)
  }
  x <- tolower(dash_scalar_character(x, arg))
  aliases <- names(choices)
  if (x %in% aliases) {
    return(unname(choices[[x]]))
  }
  valid_codes <- unique(unname(choices))
  if (x %in% valid_codes) {
    return(x)
  }
  dash_abort(
    sprintf(
      "`%s` must be one of %s.",
      arg, paste(sprintf("\"%s\"", aliases), collapse = ", ")
    ),
    class = "dashboard_parameter_error"
  )
}

dash_cycle <- function(x, allow_null = TRUE) {
  dash_choice_code(
    x, "cycle",
    c(
      month = "1", quarter = "2", year = "3",
      calendar_year = "3", fiscal_year = "4"
    ),
    allow_null
  )
}

dash_regional_rank <- function(x, allow_null = TRUE) {
  dash_choice_code(
    x, "regional_rank",
    c(country = "1", japan = "2", prefecture = "3", municipality = "4"),
    allow_null
  )
}

dash_seasonal <- function(x, allow_null = TRUE) {
  dash_choice_code(
    x, "seasonal",
    c(original = "1", seasonally_adjusted = "2"),
    allow_null
  )
}

dash_social_level <- function(x, allow_null = TRUE) {
  dash_choice_code(
    x, "level",
    c(low = "1", medium = "2", high = "3"),
    allow_null
  )
}

dash_region_level <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.numeric(x)) {
    x <- as.character(x)
  }
  if (
    !is.character(x) || length(x) < 1L || anyNA(x) ||
      any(!grepl("^[1-9][0-9]*$", x))
  ) {
    dash_abort(
      "`region_level` must be a character or numeric vector of positive codes.",
      class = "dashboard_parameter_error"
    )
  }
  paste(x, collapse = ",")
}

dash_time_code <- function(x, arg, allow_latest = FALSE) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.numeric(x) && length(x) == 1L && !is.na(x)) {
    x <- format(x, scientific = FALSE, trim = TRUE)
  }
  x <- toupper(dash_scalar_character(x, arg))
  if (allow_latest && identical(x, "99999999")) {
    return(x)
  }
  valid <- grepl(
    "^([0-9]{4}(0[1-9]|1[0-2])00|[0-9]{4}[1-4]Q00|[0-9]{4}(CY|FY)00)$",
    x
  )
  if (!valid) {
    dash_abort(
      sprintf(
        paste0(
          "`%s` must use an API time code such as ",
          "\"20240100\", \"20241Q00\", \"2024CY00\", or \"2024FY00\"."
        ),
        arg
      ),
      class = "dashboard_parameter_error"
    )
  }
  x
}

dash_check_time_pair <- function(time_from, time_to) {
  if (is.null(time_from) || is.null(time_to)) {
    return(invisible(NULL))
  }
  type <- function(x) {
    if (grepl("Q00$", x)) "quarter"
    else if (grepl("CY00$", x)) "calendar_year"
    else if (grepl("FY00$", x)) "fiscal_year"
    else "month"
  }
  if (!identical(type(time_from), type(time_to))) {
    dash_abort(
      "`time_from` and `time_to` must use the same time-code format.",
      class = "dashboard_parameter_error"
    )
  }
  if (time_from > time_to) {
    dash_abort(
      "`time_to` must not be earlier than `time_from`.",
      class = "dashboard_parameter_error"
    )
  }
  invisible(NULL)
}

dash_date8 <- function(x, arg) {
  if (is.null(x)) {
    return(NULL)
  }
  x <- dash_scalar_character(x, arg)
  parsed <- suppressWarnings(as.Date(x, format = "%Y%m%d"))
  if (!grepl("^[0-9]{8}$", x) || is.na(parsed)) {
    dash_abort(
      sprintf("`%s` must be a valid date in YYYYMMDD format.", arg),
      class = "dashboard_parameter_error"
    )
  }
  x
}

dash_value_condition <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  x <- dash_scalar_character(x, "value_condition")
  if (!grepl("^[<>]-?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))$", x)) {
    dash_abort(
      "`value_condition` must begin with '<' or '>' followed by a number.",
      class = "dashboard_parameter_error"
    )
  }
  x
}

dash_records <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(list())
  }
  if (!is.list(x)) {
    return(list(x))
  }
  if (is.null(names(x))) {
    return(x)
  }
  list(x)
}

dash_field <- function(x, name, default = "") {
  value <- x[[name]]
  if (is.null(value) || length(value) == 0L) {
    return(default)
  }
  value <- unlist(value, recursive = TRUE, use.names = FALSE)
  if (length(value) == 0L || is.na(value[[1L]])) {
    return(default)
  }
  as.character(value[[1L]])
}

dash_record_text <- function(records, field) {
  values <- vapply(
    dash_records(records),
    dash_field,
    character(1L),
    name = field,
    default = ""
  )
  values[nzchar(values)]
}

dash_bind_rows <- function(rows, empty) {
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(empty)
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

dash_period_date <- function(x) {
  if (length(x) == 0L) {
    return(as.Date(character()))
  }
  vapply_date <- function(code) {
    if (is.na(code) || !nzchar(code)) {
      return(as.Date(NA))
    }
    if (grepl("^[0-9]{4}(0[1-9]|1[0-2])00$", code)) {
      return(as.Date(paste0(substr(code, 1L, 4L), "-", substr(code, 5L, 6L), "-01")))
    }
    if (grepl("^[0-9]{4}[1-4]Q00$", code)) {
      month <- (as.integer(substr(code, 5L, 5L)) - 1L) * 3L + 1L
      return(as.Date(sprintf("%s-%02d-01", substr(code, 1L, 4L), month)))
    }
    if (grepl("^[0-9]{4}CY00$", code)) {
      return(as.Date(paste0(substr(code, 1L, 4L), "-01-01")))
    }
    if (grepl("^[0-9]{4}FY00$", code)) {
      return(as.Date(paste0(substr(code, 1L, 4L), "-04-01")))
    }
    as.Date(NA)
  }
  as.Date(
    unname(vapply(x, vapply_date, as.Date(NA))),
    origin = "1970-01-01"
  )
}

dash_element_code <- function(indicator, cycle, rank, seasonal) {
  make_two <- function(x) {
    number <- suppressWarnings(as.integer(x))
    ifelse(is.na(number), "", sprintf("%02d", number))
  }
  ok <- nzchar(indicator) & nzchar(cycle) & nzchar(rank) & nzchar(seasonal)
  out <- rep("", length(indicator))
  out[ok] <- paste0(
    indicator[ok],
    make_two(cycle[ok]),
    make_two(rank[ok]),
    make_two(seasonal[ok])
  )
  out
}

dash_sleep <- function(seconds) {
  Sys.sleep(seconds)
}

dash_pause <- function(wait) {
  wait <- dash_scalar_number(wait, "wait", min = 0)
  dash_sleep(max(1, wait))
  invisible(NULL)
}

dash_drop_null <- function(x) {
  x[!vapply(x, is.null, logical(1L))]
}
