#' Return commonly used Statistics Dashboard API codes
#'
#' The API's full category, survey, and region code systems are maintained by
#' the Statistics Bureau. This helper returns the small enumerations used
#' directly by package arguments.
#'
#' @param type One of `"cycle"`, `"regional_rank"`, `"seasonal"`,
#'   `"provisional"`, or `"social_event_level"`.
#' @param lang Label language, `"en"` or `"jp"`.
#'
#' @return A tibble containing `code`, `name`, and `type`.
#' @export
#' @examples
#' dashboard_codes("cycle")
#' dashboard_codes("regional_rank", lang = "jp")
dashboard_codes <- function(
    type = c(
      "cycle", "regional_rank", "seasonal",
      "provisional", "social_event_level"
    ),
    lang = c("en", "jp")) {
  type <- match.arg(type)
  lang <- match.arg(lang)
  values <- switch(
    type,
    cycle = list(
      code = as.character(1:4),
      en = c("Month", "Quarter", "Calendar year", "Fiscal year"),
      jp = c(
        "\u6708", "\u56DB\u534A\u671F",
        "\u5E74", "\u5E74\u5EA6"
      )
    ),
    regional_rank = list(
      code = as.character(1:4),
      en = c("Country", "Nationwide (Japan)", "Prefecture", "Municipality"),
      jp = c(
        "\u56FD", "\u5168\u56FD\uFF08\u65E5\u672C\uFF09",
        "\u90FD\u9053\u5E9C\u770C", "\u5E02\u533A\u753A\u6751"
      )
    ),
    seasonal = list(
      code = c("1", "2"),
      en = c("Original series", "Seasonally adjusted series"),
      jp = c(
        "\u539F\u6570\u5024",
        "\u5B63\u7BC0\u8ABF\u6574\u5024"
      )
    ),
    provisional = list(
      code = c("0", "1"),
      en = c("Fixed", "Preliminary"),
      jp = c("\u78BA\u5831", "\u901F\u5831")
    ),
    social_event_level = list(
      code = as.character(1:3),
      en = c("Low", "Medium", "High"),
      jp = c("\u4F4E", "\u4E2D", "\u9AD8")
    )
  )
  tibble::tibble(
    code = values$code,
    name = values[[lang]],
    type = type
  )
}
