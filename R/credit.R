#' Return Statistics Dashboard attribution and API credit
#'
#' The Statistics Dashboard asks users of its content to cite the source. When
#' publishing edited content, identify the editing entity as well. Publishers of
#' services using the API must also show a specified credit. The terms can
#' change, so verify the linked official page before publication.
#'
#' @param lang Credit language, `"en"` or `"jp"`.
#'
#' @return A named list containing `source` (the required source citation),
#'   `processed` (a template for edited content), `credit` (the required API
#'   service credit), and official URLs.
#' @export
#' @examples
#' dashboard_api_credit("en")
#' dashboard_api_credit("jp")$credit
dashboard_api_credit <- function(lang = c("en", "jp")) {
  lang <- match.arg(lang)
  if (identical(lang, "jp")) {
    return(list(
      source = paste0(
        "\u51FA\u5178\uFF1A\u7D71\u8A08\u30C0\u30C3\u30B7\u30E5\u30DC\u30FC\u30C9",
        "\uFF08https://dashboard.e-stat.go.jp/\uFF09"
      ),
      processed = paste0(
        "\u7D71\u8A08\u30C0\u30C3\u30B7\u30E5\u30DC\u30FC\u30C9",
        "\uFF08https://dashboard.e-stat.go.jp/\uFF09\u306E\u30C7\u30FC\u30BF\u3092",
        "\u52A0\u5DE5\u3057\u3066 <\u4F5C\u6210\u4E3B\u4F53> \u4F5C\u6210"
      ),
      credit = paste0(
        "\u3053\u306E\u30B5\u30FC\u30D3\u30B9\u306F\u3001",
        "\u7D71\u8A08\u30C0\u30C3\u30B7\u30E5\u30DC\u30FC\u30C9",
        "\u306EAPI\u6A5F\u80FD\u3092\u4F7F\u7528\u3057\u3066",
        "\u3044\u307E\u3059\u304C\u3001\u30B5\u30FC\u30D3\u30B9",
        "\u306E\u5185\u5BB9\u306F\u56FD\u306B\u3088\u3063\u3066",
        "\u4FDD\u8A3C\u3055\u308C\u305F\u3082\u306E\u3067\u306F",
        "\u3042\u308A\u307E\u305B\u3093\u3002"
      ),
      api_url = "https://dashboard.e-stat.go.jp/static/api",
      policy_url = "https://dashboard.e-stat.go.jp/static/sitePolicy",
      terms_url = "https://dashboard.e-stat.go.jp/static/terms"
    ))
  }
  list(
    source = "Source: Statistics Dashboard (https://dashboard.e-stat.go.jp/en/)",
    processed = paste0(
      "Created by <entity> based on the Statistics Dashboard ",
      "(https://dashboard.e-stat.go.jp/en/)"
    ),
    credit = paste0(
      "This service uses the API feature of Statistics Dashboard, ",
      "but the contents of this service are not guaranteed by the ",
      "Statistics Bureau of Japan."
    ),
    api_url = "https://dashboard.e-stat.go.jp/en/static/api",
    policy_url = "https://dashboard.e-stat.go.jp/en/static/sitePolicy",
    terms_url = "https://dashboard.e-stat.go.jp/en/static/terms"
  )
}
