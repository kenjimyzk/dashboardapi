dash_common_params <- function(
    lang,
    modified_from = NULL,
    modified_to = NULL) {
  list(
    Lang = dash_match_lang(lang),
    modifiedFrom = dash_date8(modified_from, "modified_from"),
    modifiedTo = dash_date8(modified_to, "modified_to")
  )
}

dash_indicator_annotation <- function(annotations, cycle, rank, seasonal) {
  annotations <- dash_records(annotations)
  if (length(annotations) == 0L) {
    return("")
  }
  matches <- vapply(annotations, function(item) {
    identical(dash_field(item, "@cycle"), cycle) &&
      identical(dash_field(item, "@regionalRank"), rank) &&
      identical(dash_field(item, "@isSeasonal"), seasonal)
  }, logical(1L))
  text <- vapply(
    annotations[matches],
    dash_field,
    character(1L),
    name = "@annotation",
    default = ""
  )
  paste(unique(text[nzchar(text)]), collapse = "; ")
}

dash_parse_indicators <- function(root, lang) {
  empty <- tibble::tibble(
    indicator_code = character(),
    indicator_element_code = character(),
    name = character(),
    short_name = character(),
    cycle = character(),
    cycle_name = character(),
    regional_rank = character(),
    regional_rank_name = character(),
    seasonal = character(),
    seasonal_name = character(),
    unit = character(),
    from_time = character(),
    to_time = character(),
    stat_name = character(),
    term_codes = character(),
    term_names = character(),
    term_details = character(),
    annotation = character(),
    lang = character()
  )
  if (dash_response_status(root, "getIndicatorInfo") == 1L) {
    return(empty)
  }
  objects <- dash_records(
    root$METADATA_INF$CLASS_INF$CLASS_OBJ
  )
  rows <- list()
  index <- 0L
  for (object in objects) {
    indicator_code <- dash_field(object, "@code")
    details <- dash_records(object$details$detail)
    term_codes <- paste(
      dash_record_text(details, "@code"), collapse = ";"
    )
    term_names <- paste(
      dash_record_text(details, "@name"), collapse = "; "
    )
    term_details <- paste(
      dash_record_text(details, "$"), collapse = "; "
    )
    classes <- dash_records(object$CLASS)
    for (item in classes) {
      cycle <- dash_field(item$cycle, "@code")
      rank <- dash_field(item$RegionalRank, "@code")
      seasonal <- dash_field(item$IsSeasonal, "@code")
      index <- index + 1L
      rows[[index]] <- data.frame(
        indicator_code = indicator_code,
        indicator_element_code = dash_element_code(
          indicator_code, cycle, rank, seasonal
        ),
        name = dash_field(item, "@name", dash_field(object, "@name")),
        short_name = dash_field(item, "@sname"),
        cycle = cycle,
        cycle_name = dash_field(item$cycle, "@name"),
        regional_rank = rank,
        regional_rank_name = dash_field(item$RegionalRank, "@name"),
        seasonal = seasonal,
        seasonal_name = dash_field(item$IsSeasonal, "@name"),
        unit = dash_field(item, "@unit"),
        from_time = dash_field(item, "@fromDate"),
        to_time = dash_field(item, "@toDate"),
        stat_name = dash_field(item, "@statName"),
        term_codes = term_codes,
        term_names = term_names,
        term_details = term_details,
        annotation = dash_indicator_annotation(
          object$annotations, cycle, rank, seasonal
        ),
        lang = tolower(lang),
        stringsAsFactors = FALSE
      )
    }
  }
  dash_bind_rows(rows, empty)
}

#' Search and retrieve indicator metadata
#'
#' This is the discovery endpoint for Statistics Dashboard series. The result
#' has one row per indicator element: an indicator split by data cycle,
#' regional rank, and original/seasonally adjusted status.
#'
#' @param query Optional partial match for the indicator name.
#' @param indicator_code Optional vector of 19-digit indicator codes. Up to 50
#'   codes can be sent in one metadata request.
#' @param category Optional Statistics Dashboard category code.
#' @param time,time_from,time_to Optional eight-character API time codes, such
#'   as `"20240100"`, `"20241Q00"`, `"2024CY00"`, or `"2024FY00"`.
#' @param cycle Data cycle: `"month"`, `"quarter"`, `"year"`, or
#'   `"fiscal_year"`; API codes 1--4 are also accepted.
#' @param regional_rank One of `"country"`, `"japan"`, `"prefecture"`, or
#'   `"municipality"`; API codes 1--4 are also accepted.
#' @param seasonal `"original"` or `"seasonally_adjusted"`; API codes 1 and 2
#'   are also accepted.
#' @param stat_code,stat_name Optional statistical survey code or partial name.
#' @param modified_from,modified_to Optional metadata update dates in
#'   `YYYYMMDD` format.
#' @param lang Response language, `"en"` or `"jp"`.
#' @param timeout Request timeout in seconds.
#' @param retries Number of retries for transient failures.
#'
#' @return A tibble with one row per indicator element.
#' @export
#' @examples
#' \dontrun{
#' dashboard_indicators(query = "Total population", lang = "en")
#' dashboard_indicators(
#'   category = "0201", cycle = "year", regional_rank = "prefecture"
#' )
#' }
dashboard_indicators <- function(
    query = NULL,
    indicator_code = NULL,
    category = NULL,
    time = NULL,
    time_from = NULL,
    time_to = NULL,
    cycle = NULL,
    regional_rank = NULL,
    seasonal = NULL,
    stat_code = NULL,
    stat_name = NULL,
    modified_from = NULL,
    modified_to = NULL,
    lang = dash_default("lang", "en"),
    timeout = dash_default("timeout", 30),
    retries = dash_default("retries", 3)) {
  codes <- if (is.null(indicator_code)) {
    NULL
  } else {
    dash_character_vector(
      indicator_code, "indicator_code", max = 50L,
      pattern = "^[0-9]{19}$", allow_null = TRUE
    )
  }
  time <- dash_time_code(time, "time", allow_latest = FALSE)
  time_from <- dash_time_code(time_from, "time_from")
  time_to <- dash_time_code(time_to, "time_to")
  dash_check_time_pair(time_from, time_to)
  lang <- dash_match_lang(lang)
  params <- c(
    list(
      Lang = lang,
      IndicatorCode = dash_join(codes),
      Category = dash_optional_character(category, "category"),
      Time = time,
      TimeFrom = time_from,
      TimeTo = time_to,
      Cycle = dash_cycle(cycle),
      RegionalRank = dash_regional_rank(regional_rank),
      IsSeasonalAdjustment = dash_seasonal(seasonal),
      StatCode = dash_optional_character(stat_code, "stat_code"),
      StatName = dash_optional_character(stat_name, "stat_name"),
      SearchIndicatorWord = dash_optional_character(query, "query"),
      modifiedFrom = dash_date8(modified_from, "modified_from"),
      modifiedTo = dash_date8(modified_to, "modified_to")
    )
  )
  root <- dash_fetch_json(
    "getIndicatorInfo", params, timeout = timeout, retries = retries
  )
  out <- dash_parse_indicators(root, lang)
  attr(out, "retrieved_at") <- Sys.time()
  attr(out, "query") <- dash_drop_null(params)
  out
}

#' Search Statistics Dashboard indicators
#'
#' A concise alias for [dashboard_indicators()] with a required search phrase.
#'
#' @param query Partial indicator-name match.
#' @inheritParams dashboard_indicators
#' @param ... Additional filters passed to [dashboard_indicators()].
#' @return A tibble with one row per matching indicator element.
#' @export
#' @examples
#' \dontrun{
#' dashboard_search("unemployment rate")
#' dashboard_search(intToUtf8(c(23436, 20840, 22833, 26989, 29575)), lang = "jp")
#' }
dashboard_search <- function(
    query,
    lang = dash_default("lang", "en"),
    ...) {
  query <- dash_scalar_character(query, "query")
  dashboard_indicators(query = query, lang = lang, ...)
}

dash_parse_regions <- function(root, lang) {
  empty <- tibble::tibble(
    parent_region_code = character(),
    parent_region = character(),
    parent_hiragana = character(),
    region_code = character(),
    region = character(),
    level = character(),
    hiragana = character(),
    from_time = character(),
    to_time = character(),
    lang = character()
  )
  if (dash_response_status(root, "getRegionInfo") == 1L) {
    return(empty)
  }
  objects <- dash_records(root$METADATA_INF$CLASS_INF$CLASS_OBJ)
  rows <- list()
  index <- 0L
  for (object in objects) {
    children <- dash_records(object$CLASS)
    for (child in children) {
      index <- index + 1L
      rows[[index]] <- data.frame(
        parent_region_code = dash_field(object, "@parentRegionCode"),
        parent_region = dash_field(object, "@name"),
        parent_hiragana = dash_field(object, "@hiragana"),
        region_code = dash_field(child, "@regionCode"),
        region = dash_field(child, "@name", dash_field(child, "$")),
        level = dash_field(child, "@level"),
        hiragana = dash_field(child, "@hiragana"),
        from_time = dash_field(child, "@fromDate"),
        to_time = dash_field(child, "@toDate"),
        lang = tolower(lang),
        stringsAsFactors = FALSE
      )
    }
  }
  dash_bind_rows(rows, empty)
}

#' Search and retrieve region metadata
#'
#' @param query Optional partial match for a region name.
#' @param region_code Optional vector of up to 50 five-digit Japanese region
#'   codes or three-letter ISO country codes.
#' @param parent_region_code Optional five-digit parent-region code. For
#'   example, `"00000"` returns Japan's prefectures.
#' @param region_level Optional vector of official region-level codes.
#' @inheritParams dashboard_indicators
#' @return A tibble of regions and their parent regions.
#' @export
#' @examples
#' \dontrun{
#' dashboard_regions(parent_region_code = "00000")
#' dashboard_regions(query = "Tokyo", lang = "en")
#' }
dashboard_regions <- function(
    query = NULL,
    region_code = NULL,
    parent_region_code = NULL,
    time = NULL,
    time_from = NULL,
    time_to = NULL,
    region_level = NULL,
    modified_from = NULL,
    modified_to = NULL,
    lang = dash_default("lang", "en"),
    timeout = dash_default("timeout", 30),
    retries = dash_default("retries", 3)) {
  codes <- if (is.null(region_code)) {
    NULL
  } else {
    dash_region_codes(region_code, max = 50L)
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
  time <- dash_time_code(time, "time")
  time_from <- dash_time_code(time_from, "time_from")
  time_to <- dash_time_code(time_to, "time_to")
  dash_check_time_pair(time_from, time_to)
  lang <- dash_match_lang(lang)
  params <- list(
    Lang = lang,
    RegionCode = dash_join(codes),
    ParentRegionCode = parent_region_code,
    Time = time,
    TimeFrom = time_from,
    TimeTo = time_to,
    RegionLevel = dash_region_level(region_level),
    SearchRegionWord = dash_optional_character(query, "query"),
    modifiedFrom = dash_date8(modified_from, "modified_from"),
    modifiedTo = dash_date8(modified_to, "modified_to")
  )
  root <- dash_fetch_json(
    "getRegionInfo", params, timeout = timeout, retries = retries
  )
  out <- dash_parse_regions(root, lang)
  attr(out, "retrieved_at") <- Sys.time()
  attr(out, "query") <- dash_drop_null(params)
  out
}

dash_parse_simple_class <- function(root, endpoint, fields, lang) {
  empty_values <- lapply(fields, function(x) character())
  names(empty_values) <- names(fields)
  empty_values$lang <- character()
  empty <- tibble::as_tibble(empty_values)
  if (dash_response_status(root, endpoint) == 1L) {
    return(empty)
  }
  containers <- dash_records(root$METADATA_INF$CLASS_INF$CLASS_OBJ)
  records <- unlist(
    lapply(containers, function(x) dash_records(x$CLASS)),
    recursive = FALSE
  )
  rows <- lapply(records, function(item) {
    values <- lapply(fields, function(field) dash_field(item, field))
    values$lang <- tolower(lang)
    as.data.frame(values, stringsAsFactors = FALSE)
  })
  dash_bind_rows(rows, empty)
}

#' Search and retrieve statistical term metadata
#'
#' @param query Optional partial match for a term name.
#' @param category,indicator_code,stat_code Optional metadata filters.
#' @inheritParams dashboard_indicators
#' @return A tibble of statistical terms and definitions.
#' @export
#' @examples
#' \dontrun{
#' dashboard_terms(category = "0201", lang = "en")
#' dashboard_terms(query = intToUtf8(c(20154, 21475)), lang = "jp")
#' }
dashboard_terms <- function(
    query = NULL,
    category = NULL,
    indicator_code = NULL,
    stat_code = NULL,
    modified_from = NULL,
    modified_to = NULL,
    lang = dash_default("lang", "en"),
    timeout = dash_default("timeout", 30),
    retries = dash_default("retries", 3)) {
  if (!is.null(indicator_code)) {
    indicator_code <- dash_character_vector(
      indicator_code, "indicator_code", max = 1L,
      pattern = "^[0-9]{19}$"
    )
  }
  lang <- dash_match_lang(lang)
  params <- list(
    Lang = lang,
    Category = dash_optional_character(category, "category"),
    IndicatorCode = dash_join(indicator_code),
    StatCode = dash_optional_character(stat_code, "stat_code"),
    SearchTermWord = dash_optional_character(query, "query"),
    modifiedFrom = dash_date8(modified_from, "modified_from"),
    modifiedTo = dash_date8(modified_to, "modified_to")
  )
  root <- dash_fetch_json(
    "getTermInfo", params, timeout = timeout, retries = retries
  )
  out <- dash_parse_simple_class(
    root, "getTermInfo",
    c(
      category = "@category", name = "@name", code = "@code",
      detail = "@detail", link_url = "@linkURL"
    ),
    lang
  )
  attr(out, "retrieved_at") <- Sys.time()
  attr(out, "query") <- dash_drop_null(params)
  out
}

dash_parse_events <- function(root, lang) {
  empty <- tibble::tibble(
    event_code = character(),
    event = character(),
    level = character(),
    from_time = character(),
    to_time = character(),
    category_code = character(),
    category = character(),
    lang = character()
  )
  if (dash_response_status(root, "getSocialEventInfo") == 1L) {
    return(empty)
  }
  events <- dash_records(root$METADATA_INF$CLASS_INF$CLASS_OBJ)
  rows <- list()
  index <- 0L
  for (event in events) {
    categories <- dash_records(event$CLASS)
    if (length(categories) == 0L) {
      categories <- list(list())
    }
    for (category in categories) {
      index <- index + 1L
      rows[[index]] <- data.frame(
        event_code = dash_field(event, "@code"),
        event = dash_field(event, "@name"),
        level = dash_field(event, "@level"),
        from_time = dash_field(event, "@fromTime"),
        to_time = dash_field(event, "@toTime"),
        category_code = dash_field(category, "@code"),
        category = dash_field(category, "@name", dash_field(category, "$")),
        lang = tolower(lang),
        stringsAsFactors = FALSE
      )
    }
  }
  dash_bind_rows(rows, empty)
}

#' Search and retrieve social-event metadata
#'
#' @param level Event importance: `"low"`, `"medium"`, or `"high"`; API
#'   codes 1--3 are also accepted.
#' @param category Optional Statistics Dashboard category code.
#' @inheritParams dashboard_indicators
#' @return A tibble with one row per event-category association.
#' @export
#' @examples
#' \dontrun{
#' dashboard_events(category = "0201", level = "high")
#' }
dashboard_events <- function(
    time = NULL,
    time_from = NULL,
    time_to = NULL,
    level = NULL,
    category = NULL,
    modified_from = NULL,
    modified_to = NULL,
    lang = dash_default("lang", "en"),
    timeout = dash_default("timeout", 30),
    retries = dash_default("retries", 3)) {
  time <- dash_time_code(time, "time")
  time_from <- dash_time_code(time_from, "time_from")
  time_to <- dash_time_code(time_to, "time_to")
  dash_check_time_pair(time_from, time_to)
  lang <- dash_match_lang(lang)
  params <- list(
    Lang = lang,
    Time = time,
    TimeFrom = time_from,
    TimeTo = time_to,
    SocialEventLevel = dash_social_level(level),
    Category = dash_optional_character(category, "category"),
    modifiedFrom = dash_date8(modified_from, "modified_from"),
    modifiedTo = dash_date8(modified_to, "modified_to")
  )
  root <- dash_fetch_json(
    "getSocialEventInfo", params, timeout = timeout, retries = retries
  )
  out <- dash_parse_events(root, lang)
  attr(out, "retrieved_at") <- Sys.time()
  attr(out, "query") <- dash_drop_null(params)
  out
}

#' Search and retrieve statistical-survey metadata
#'
#' @param query Optional partial match for a survey name.
#' @param indicator_code Optional vector of up to 50 indicator codes.
#' @param stat_code Optional statistical survey code.
#' @inheritParams dashboard_indicators
#' @return A tibble of statistical surveys.
#' @export
#' @examples
#' \dontrun{
#' dashboard_surveys(query = "Population Census", lang = "en")
#' }
dashboard_surveys <- function(
    query = NULL,
    indicator_code = NULL,
    stat_code = NULL,
    modified_from = NULL,
    modified_to = NULL,
    lang = dash_default("lang", "en"),
    timeout = dash_default("timeout", 30),
    retries = dash_default("retries", 3)) {
  codes <- if (is.null(indicator_code)) {
    NULL
  } else {
    dash_character_vector(
      indicator_code, "indicator_code", max = 50L,
      pattern = "^[0-9]{19}$"
    )
  }
  lang <- dash_match_lang(lang)
  params <- list(
    Lang = lang,
    IndicatorCode = dash_join(codes),
    StatCode = dash_optional_character(stat_code, "stat_code"),
    SearchSurveyWord = dash_optional_character(query, "query"),
    modifiedFrom = dash_date8(modified_from, "modified_from"),
    modifiedTo = dash_date8(modified_to, "modified_to")
  )
  root <- dash_fetch_json(
    "getStatInfo", params, timeout = timeout, retries = retries
  )
  out <- dash_parse_simple_class(
    root, "getStatInfo",
    c(
      stat_code = "@code", name = "@name", agency = "@agency",
      kind = "@kind", summary = "@summary", link_url = "@linkUrl"
    ),
    lang
  )
  attr(out, "retrieved_at") <- Sys.time()
  attr(out, "query") <- dash_drop_null(params)
  out
}
