# # flag_iati
# # Works on title_narrative and description_narrative for HumanitarianFlags and EducationFlags (on FoodSec subset)
# 
# flag_iati <- function(search_terms, column_name) {
#   # Create a single regex pattern with the terms, separated by `|`
#   # pattern <- paste(search_terms, collapse = "|")
#   pattern <- paste0("\\b(", paste(search_terms, collapse = "|"), ")\\b")
#   # Flag the dataset using the pattern
#   full_data <- full_data %>%
#     mutate(
#       !!sym(column_name) := ifelse(
#         str_detect(title_narrative, regex(pattern, ignore_case = TRUE)) | 
#           str_detect(description_narrative, regex(pattern, ignore_case = TRUE)),
#         "YES", 
#         "NO"
#       )
#     )
#   # Return the modified dataset
#   return(full_data)
# }

# requirements/flag_iati.R
# Needs: dplyr, stringr, rlang
flag_iati <- function(df, terms, column_name,
                      title_col = "title_narrative",
                      desc_col  = "description_narrative",
                      use_word_boundaries = FALSE) {
  stopifnot(is.data.frame(df))
  if (!all(c(title_col, desc_col) %in% names(df))) {
    stop("flag_iati(): title/description columns not found in df.")
  }
  if (length(terms) == 0) {
    df[[column_name]] <- "NO"
    return(df)
  }
  
  # Escape regex metacharacters in terms
  safe_terms <- stringr::str_replace_all(terms, "([\\^$.|?*+()\\[\\]{}\\\\])", "\\\\\\1")
  sep <- if (use_word_boundaries) ")\\b|" else ")|("
  pattern <- paste0("(", paste(safe_terms, collapse = sep), ")")
  if (use_word_boundaries) pattern <- paste0("\\b", pattern, "\\b")
  
  # NA-safe detection
  has_term <- function(x) stringr::str_detect(x %||% "", stringr::regex(pattern, ignore_case = TRUE))
  
  df <- dplyr::mutate(
    df,
    !!rlang::sym(column_name) := dplyr::if_else(
      has_term(.data[[title_col]]) | has_term(.data[[desc_col]]),
      "YES", "NO", missing = "NO"
    )
  )
  df
}
`%||%` <- function(x, y) if (is.null(x)) y else x