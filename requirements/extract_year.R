extract_year <- function(date_col) {
  # Try to handle different date/time formats automatically
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
  
  # Extract year if parsing succeeded
  year(parsed_date)
}
