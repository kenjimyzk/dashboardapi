fixture_indicator_root <- function(status = "0") {
  list(
    RESULT = list(status = status, errorMsg = "Success."),
    METADATA_INF = list(
      CLASS_INF = list(
        CLASS_OBJ = list(
          list(
            "@name" = "Total population (Both sexes)",
            "@code" = "0201010000000010000",
            details = list(
              detail = list(
                list(
                  "@code" = "0201010001",
                  "@name" = "Total population",
                  "$" = "Population definition."
                )
              )
            ),
            annotations = list(
              list(
                "@cycle" = "3",
                "@regionalRank" = "2",
                "@isSeasonal" = "1",
                "@annotation" = "Sample annotation."
              )
            ),
            CLASS = list(
              list(
                "@name" = "Total population (Both sexes)",
                "@sname" = "Total population",
                "@fromDate" = "1920CY00",
                "@toDate" = "9999CY00",
                cycle = list("@code" = "3", "@name" = "Calendar Year"),
                RegionalRank = list("@code" = "2", "@name" = "Japan"),
                IsSeasonal = list("@code" = "1", "@name" = "Original Series"),
                "@statName" = "Population Census / Population Estimates",
                "@unit" = "person"
              )
            )
          )
        )
      )
    )
  )
}

fixture_region_root <- function() {
  list(
    RESULT = list(status = "0", errorMsg = "Success."),
    METADATA_INF = list(
      CLASS_INF = list(
        CLASS_OBJ = list(
          list(
            "@parentRegionCode" = "00000",
            "@name" = "Japan",
            "@hiragana" = "",
            CLASS = list(
              list(
                "@regionCode" = "13000",
                "@name" = "Tokyo-to",
                "@level" = "3",
                "@hiragana" = "",
                "@fromDate" = "190001",
                "@toDate" = "999912"
              )
            )
          )
        )
      )
    )
  )
}

fixture_term_root <- function() {
  list(
    RESULT = list(status = "0", errorMsg = "Success."),
    METADATA_INF = list(
      CLASS_INF = list(
        CLASS_OBJ = list(
          CLASS = list(
            list(
              "@category" = "Population",
              "@name" = "Total population",
              "@code" = "0201010001",
              "@detail" = "Population definition.",
              "@linkURL" = "https://example.test/population"
            )
          )
        )
      )
    )
  )
}

fixture_event_root <- function() {
  list(
    RESULT = list(status = "0", errorMsg = "Success."),
    METADATA_INF = list(
      CLASS_INF = list(
        CLASS_OBJ = list(
          list(
            "@code" = "00003",
            "@name" = "Jinmu boom",
            "@level" = "3",
            "@fromTime" = "Dec.1954",
            "@toTime" = "Jun.1957",
            CLASS = list(
              list("@code" = "0201", "@name" = "Population")
            )
          )
        )
      )
    )
  )
}

fixture_survey_root <- function() {
  list(
    RESULT = list(status = "0", errorMsg = "Success."),
    METADATA_INF = list(
      CLASS_INF = list(
        CLASS_OBJ = list(
          CLASS = list(
            list(
              "@code" = "20020101",
              "@name" = "Population Census / Population Estimates",
              "@agency" = "Statistics Bureau of Japan",
              "@kind" = "Fundamental Statistics",
              "@summary" = "Population statistics.",
              "@linkUrl" = "https://example.test/census"
            )
          )
        )
      )
    )
  )
}

fixture_data_root <- function(value = "125000000") {
  class_object <- function(id, name, classes) {
    list("@id" = id, "@name" = name, CLASS = classes)
  }
  list(
    RESULT = list(status = "0", errorMsg = "Success."),
    STATISTICAL_DATA = list(
      RESULT_INF = list(TOTAL_NUMBER = "1"),
      TABLE_INF = list(
        STAT_NAME = list(
          list("@code" = "20020101", "$" = "Population Census")
        )
      ),
      CLASS_INF = list(
        CLASS_OBJ = list(
          class_object(
            "indicator", "Indicator",
            list(list(
              "@code" = "0201010000000010000",
              "@name" = "Total population (Both sexes)"
            ))
          ),
          class_object(
            "unit", "Unit",
            list(list("@code" = "090", "$" = "person"))
          ),
          class_object(
            "regionCode", "Region",
            list(list("@code" = "00000", "@name" = "Japan"))
          ),
          class_object(
            "time", "Time axis",
            list(list("@code" = "2024CY00", "@name" = "2024"))
          ),
          class_object(
            "cycle", "Cycle",
            list(list("@code" = "3", "$" = "Calendar Year"))
          ),
          class_object(
            "regionalRank", "Regional rank",
            list(list("@code" = "2", "$" = "Japan"))
          ),
          class_object(
            "isSeasonal", "Original or adjusted",
            list(list("@code" = "1", "$" = "Original Series"))
          ),
          class_object(
            "isProvisional", "Preliminary or fixed",
            list(list("@code" = "0", "$" = "Fixed"))
          )
        )
      ),
      DATA_INF = list(
        DATA_OBJ = list(
          list(
            VALUE = list(
              "@indicator" = "0201010000000010000",
              "@unit" = "090",
              "@stat" = "20020101",
              "@regionCode" = "00000",
              "@time" = "2024CY00",
              "@cycle" = "3",
              "@regionRank" = "2",
              "@isSeasonal" = "1",
              "@isProvisional" = "0",
              "$" = value
            ),
            CELL_ANNOTATIONS = list("$" = "Fixture note.")
          )
        )
      )
    )
  )
}

