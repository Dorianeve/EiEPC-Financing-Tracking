normalize_to_iso <- function(date_col) {
  parsed_date <- suppressWarnings(parse_date_time(
    date_col,
    orders = c(
      "ymd", "dmy", "mdy",       # Date formats
      "ymd HMS", "dmy HMS", "mdy HMS", # Datetime formats
      "ymd HM", "dmy HM", "mdy HM",
      "ymd H", "dmy H", "mdy H"
    ),
    tz = "UTC"
  ))
  
  # ✅ Always return ISO date (YYYY-MM-DD)
  ifelse(
    is.na(parsed_date),
    NA_character_,
    format(as.Date(parsed_date), "%Y-%m-%d")
  )
}
