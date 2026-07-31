dash_class_objects <- function(statistical_data) {
  dash_records(statistical_data$CLASS_INF$CLASS_OBJ)
}

dash_class_lookup <- function(statistical_data, id) {
  objects <- dash_class_objects(statistical_data)
  positions <- vapply(
    objects, function(x) identical(dash_field(x, "@id"), id),
    logical(1L)
  )
  if (!any(positions)) {
    return(character())
  }
  classes <- dash_records(objects[[which(positions)[1L]]]$CLASS)
  codes <- vapply(
    classes, dash_field, character(1L), name = "@code", default = ""
  )
  labels <- vapply(classes, function(x) {
    dash_field(x, "@name", dash_field(x, "$"))
  }, character(1L))
  stats::setNames(labels, codes)
}

dash_stat_lookup <- function(statistical_data) {
  records <- dash_records(statistical_data$TABLE_INF$STAT_NAME)
  codes <- vapply(
    records, dash_field, character(1L), name = "@code", default = ""
  )
  labels <- vapply(
    records, dash_field, character(1L), name = "$", default = ""
  )
  stats::setNames(labels, codes)
}

dash_lookup <- function(map, code) {
  if (!nzchar(code) || length(map) == 0L || !code %in% names(map)) {
    return("")
  }
  unname(map[[code]])
}

dash_data_annotation <- function(object) {
  annotation <- object$CELL_ANNOTATIONS
  if (is.null(annotation)) {
    return("")
  }
  values <- c(
    dash_record_text(annotation, "$"),
    dash_record_text(annotation$CELL_ANNOTATION, "$")
  )
  paste(unique(values[nzchar(values)]), collapse = "; ")
}

dash_empty_data <- function() {
  tibble::tibble(
    indicator = character(),
    indicator_code = character(),
    indicator_element_code = character(),
    indicator_name = character(),
    unit_code = character(),
    unit = character(),
    stat_code = character(),
    stat_name = character(),
    region_code = character(),
    region = character(),
    time = character(),
    date = as.Date(character()),
    cycle = character(),
    cycle_name = character(),
    regional_rank = character(),
    regional_rank_name = character(),
    seasonal = character(),
    seasonal_name = character(),
    provisional = logical(),
    provisional_code = character(),
    provisional_name = character(),
    value = double(),
    value_raw = character(),
    annotation = character()
  )
}

dash_parse_data <- function(root, aliases = NULL) {
  empty <- dash_empty_data()
  if (dash_response_status(root, "getData") == 1L) {
    return(empty)
  }
  statistical_data <- root$STATISTICAL_DATA
  if (!is.list(statistical_data)) {
    dash_abort(
      "The API response does not contain statistical data.",
      class = "dashboard_parse_error"
    )
  }
  maps <- list(
    indicator = dash_class_lookup(statistical_data, "indicator"),
    unit = dash_class_lookup(statistical_data, "unit"),
    region = dash_class_lookup(statistical_data, "regionCode"),
    time = dash_class_lookup(statistical_data, "time"),
    cycle = dash_class_lookup(statistical_data, "cycle"),
    rank = dash_class_lookup(statistical_data, "regionalRank"),
    seasonal = dash_class_lookup(statistical_data, "isSeasonal"),
    provisional = dash_class_lookup(statistical_data, "isProvisional"),
    stat = dash_stat_lookup(statistical_data)
  )
  objects <- dash_records(statistical_data$DATA_INF$DATA_OBJ)
  rows <- list()
  index <- 0L
  for (object in objects) {
    values <- dash_records(object$VALUE)
    for (item in values) {
      indicator_code <- dash_field(item, "@indicator")
      unit_code <- dash_field(item, "@unit")
      stat_code <- dash_field(item, "@stat")
      region_code <- dash_field(item, "@regionCode")
      time <- dash_field(item, "@time")
      cycle <- dash_field(item, "@cycle")
      rank <- dash_field(item, "@regionRank")
      seasonal <- dash_field(item, "@isSeasonal")
      provisional <- dash_field(item, "@isProvisional")
      raw_value <- dash_field(item, "$")
      numeric_value <- suppressWarnings(as.numeric(raw_value))
      if (!nzchar(raw_value) || !is.finite(numeric_value)) {
        numeric_value <- NA_real_
      }
      alias <- indicator_code
      if (
        !is.null(aliases) && indicator_code %in% names(aliases) &&
          nzchar(aliases[[indicator_code]])
      ) {
        alias <- aliases[[indicator_code]]
      }
      index <- index + 1L
      rows[[index]] <- data.frame(
        indicator = alias,
        indicator_code = indicator_code,
        indicator_element_code = dash_element_code(
          indicator_code, cycle, rank, seasonal
        ),
        indicator_name = dash_lookup(maps$indicator, indicator_code),
        unit_code = unit_code,
        unit = dash_lookup(maps$unit, unit_code),
        stat_code = stat_code,
        stat_name = dash_lookup(maps$stat, stat_code),
        region_code = region_code,
        region = dash_lookup(maps$region, region_code),
        time = time,
        date = dash_period_date(time),
        cycle = cycle,
        cycle_name = dash_lookup(maps$cycle, cycle),
        regional_rank = rank,
        regional_rank_name = dash_lookup(maps$rank, rank),
        seasonal = seasonal,
        seasonal_name = dash_lookup(maps$seasonal, seasonal),
        provisional = identical(provisional, "1"),
        provisional_code = provisional,
        provisional_name = dash_lookup(maps$provisional, provisional),
        value = numeric_value,
        value_raw = raw_value,
        annotation = dash_data_annotation(object),
        stringsAsFactors = FALSE
      )
    }
  }
  dash_bind_rows(rows, empty)
}

dash_widen_data <- function(data) {
  if (nrow(data) == 0L) {
    return(tibble::tibble(
      region_code = character(), region = character(),
      time = character(), date = as.Date(character())
    ))
  }
  labels <- unique(data$indicator)
  if (any(!nzchar(labels)) || anyDuplicated(labels)) {
    dash_abort(
      "Indicator aliases must be non-empty and unique for wide output.",
      class = "dashboard_parameter_error"
    )
  }
  id_columns <- c(
    "region_code", "region", "time", "date", "cycle", "cycle_name",
    "regional_rank", "regional_rank_name", "seasonal", "seasonal_name",
    "stat_code", "stat_name"
  )
  key_part <- function(x) {
    if (inherits(x, "Date")) as.character(x) else as.character(x)
  }
  make_key <- function(x) {
    do.call(
      paste,
      c(lapply(x[id_columns], key_part), list(sep = "\r"))
    )
  }
  observation_key <- paste(make_key(data), data$indicator, sep = "\r")
  if (anyDuplicated(observation_key)) {
    dash_abort(
      paste0(
        "The query returned more than one value for the same wide-output cell. ",
        "Add cycle, regional-rank, seasonal, or survey filters, or use long output."
      ),
      class = "dashboard_wide_error"
    )
  }
  id <- unique(data[id_columns])
  key <- make_key(id)
  for (label in labels) {
    subset <- data[data$indicator == label, , drop = FALSE]
    id[[label]] <- subset$value[match(key, make_key(subset))]
  }
  tibble::as_tibble(id)
}

#' Retrieve Statistics Dashboard observations
#'
#' `dashboard_data()` retrieves one or more indicators and returns one
#' indicator-region-time observation per row. The API permits five indicators
#' and 50 regions per request. Longer vectors are split automatically, with at
#' least one second between requests.
#'
#' Named `indicator_code` vectors create aliases in the `indicator` column and
#' in wide output, following the style of `WDI::WDI()`.
#'
#' @param indicator_code Character vector of 19-digit indicator codes. Names
#'   become aliases. Requests are automatically batched in groups of five.
#' @param region_code Optional vector of five-digit Japanese region codes or
#'   three-letter ISO country codes. Requests are automatically batched in
#'   groups of 50.
#' @param parent_region_code Optional five-digit parent-region code.
#' @param region_level Optional official region-level code.
#' @param time,time_from,time_to Optional API time codes. Use `"20240100"` for
#'   January 2024, `"20241Q00"` for 2024 Q1, `"2024CY00"` for calendar year
#'   2024, or `"2024FY00"` for fiscal year 2024.
#' @param cycle Data cycle: `"month"`, `"quarter"`, `"year"`, or
#'   `"fiscal_year"`; API codes 1--4 are also accepted.
#' @param regional_rank One of `"country"`, `"japan"`, `"prefecture"`, or
#'   `"municipality"`; API codes 1--4 are also accepted.
#' @param seasonal `"original"` or `"seasonally_adjusted"`; API codes 1 and 2
#'   are also accepted.
#' @param stat_name Optional partial match for a statistical survey name.
#' @param value_condition Optional strict numeric filter such as `">100"` or
#'   `"<0"`.
#' @param wide If `FALSE` (default), return normalized long data. If `TRUE`,
#'   put each indicator or alias in its own column.
#' @param lang Response language, `"en"` or `"jp"`.
#' @param wait Requested seconds between automatically batched requests.
#'   Values below one are treated as one when another request is required.
#' @param timeout Request timeout in seconds.
#' @param retries Number of retries for transient failures.
#'
#' @return A tibble. Long output retains raw codes and labels, an R `Date`,
#'   numeric `value`, original `value_raw`, and annotations.
#' @export
#' @examples
#' \dontrun{
#' population <- dashboard_data(
#'   indicator_code = c(population = "0201010000000010000"),
#'   region_code = "00000",
#'   time_from = "2020CY00",
#'   time_to = "2024CY00",
#'   cycle = "year",
#'   regional_rank = "japan",
#'   seasonal = "original"
#' )
#' }
dashboard_data <- function(
    indicator_code,
    region_code = NULL,
    parent_region_code = NULL,
    region_level = NULL,
    time = NULL,
    time_from = NULL,
    time_to = NULL,
    cycle = NULL,
    regional_rank = NULL,
    seasonal = NULL,
    stat_name = NULL,
    value_condition = NULL,
    wide = FALSE,
    lang = dash_default("lang", "en"),
    wait = dash_default("wait", 1),
    timeout = dash_default("timeout", 30),
    retries = dash_default("retries", 3)) {
  original_names <- names(indicator_code)
  codes <- dash_indicator_codes(indicator_code)
  if (anyDuplicated(codes)) {
    dash_abort(
      "`indicator_code` must not contain duplicates.",
      class = "dashboard_parameter_error"
    )
  }
  regions <- if (is.null(region_code)) {
    NULL
  } else {
    dash_region_codes(toupper(region_code))
  }
  if (!is.null(regions) && anyDuplicated(regions)) {
    dash_abort(
      "`region_code` must not contain duplicates.",
      class = "dashboard_parameter_error"
    )
  }
  if (!is.null(parent_region_code)) {
    parent_region_code <- dash_scalar_character(
      parent_region_code, "parent_region_code"
    )
    if (!grepl("^[0-9]{5}$", parent_region_code)) {
      dash_abort(
        "`parent_region_code` must be a five-digit code.",
        class = "dashboard_parameter_error"
      )
    }
  }
  time <- dash_time_code(time, "time", allow_latest = FALSE)
  time_from <- dash_time_code(time_from, "time_from")
  time_to <- dash_time_code(time_to, "time_to")
  dash_check_time_pair(time_from, time_to)
  wide <- dash_flag(wide, "wide")
  wait <- dash_scalar_number(wait, "wait", min = 0)
  timeout <- dash_scalar_number(timeout, "timeout", min = 0)
  retries <- dash_scalar_number(retries, "retries", min = 0, integer = TRUE)
  lang <- dash_match_lang(lang)

  aliases <- codes
  names(aliases) <- codes
  if (!is.null(original_names)) {
    use <- !is.na(original_names) & nzchar(original_names)
    aliases[codes[use]] <- original_names[use]
  }
  if (wide && anyDuplicated(unname(aliases))) {
    dash_abort(
      "Named `indicator_code` aliases must be unique for wide output.",
      class = "dashboard_parameter_error"
    )
  }

  indicator_chunks <- dash_chunks(codes, .dashboardapi_max_indicators)
  region_chunks <- dash_chunks(regions, .dashboardapi_max_regions)
  outputs <- list()
  request_number <- 0L
  for (indicator_chunk in indicator_chunks) {
    for (region_chunk in region_chunks) {
      request_number <- request_number + 1L
      if (request_number > 1L) {
        dash_pause(wait)
      }
      params <- list(
        Lang = lang,
        IndicatorCode = dash_join(indicator_chunk),
        RegionCode = dash_join(region_chunk),
        ParentRegionCode = parent_region_code,
        RegionLevel = dash_region_level(region_level),
        Time = time,
        TimeFrom = time_from,
        TimeTo = time_to,
        Cycle = dash_cycle(cycle),
        RegionalRank = dash_regional_rank(regional_rank),
        IsSeasonalAdjustment = dash_seasonal(seasonal),
        StatName = dash_optional_character(stat_name, "stat_name"),
        ValueCondition = dash_value_condition(value_condition),
        MetaGetFlg = "Y",
        SectionHeaderFlg = "1"
      )
      root <- dash_fetch_json(
        "getData", params, timeout = timeout, retries = retries, wait = wait
      )
      outputs[[request_number]] <- dash_parse_data(root, aliases)
    }
  }
  out <- if (length(outputs) == 0L) {
    dash_empty_data()
  } else {
    dash_bind_rows(lapply(outputs, as.data.frame), dash_empty_data())
  }
  if (nrow(out) > 0L) {
    key <- paste(
      out$indicator_code, out$region_code, out$time, out$cycle,
      out$regional_rank, out$seasonal, out$stat_code, sep = "\r"
    )
    duplicate <- duplicated(key)
    if (any(duplicate)) {
      same_value <- out$value[match(key[duplicate], key)] == out$value[duplicate]
      same_value[is.na(same_value)] <-
        is.na(out$value[match(key[duplicate], key)]) & is.na(out$value[duplicate])
      if (!all(same_value)) {
        dash_abort(
          "Batched API responses contained conflicting duplicate observations.",
          class = "dashboard_incomplete_download"
        )
      }
      out <- out[!duplicated(key), , drop = FALSE]
    }
  }
  attr(out, "retrieved_at") <- Sys.time()
  attr(out, "query") <- list(
    indicator_code = codes,
    region_code = regions,
    parent_region_code = parent_region_code,
    region_level = region_level,
    time = time,
    time_from = time_from,
    time_to = time_to,
    cycle = cycle,
    regional_rank = regional_rank,
    seasonal = seasonal,
    stat_name = stat_name,
    value_condition = value_condition,
    lang = tolower(lang)
  )
  if (wide) dash_widen_data(out) else tibble::as_tibble(out)
}

