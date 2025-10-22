# Function to apply flags
# this function necessitates the columns ActivityName and ActivityDescription

group_flag <- function(df, search_terms, column_name) {
  # Create a single regex pattern with the terms, separated by `|`
  # pattern <- paste(search_terms, collapse = "|")
  pattern <- paste0("\\b(", paste(search_terms, collapse = "|"), ")\\b")
  
  # Flag the dataset using the pattern
  df <- df %>%
    mutate(
      !!sym(column_name) := ifelse(
        str_detect(ActivityName, regex(pattern, ignore_case = TRUE)) | 
          str_detect(ActivityDescription, regex(pattern, ignore_case = TRUE)),
        "YES", 
        "NO"
      )
    ) 
  
  # Return the modified dataset
  return(df)
}