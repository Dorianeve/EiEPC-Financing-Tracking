# function to merge_data_types between education and foodsec subset
# education - df1 is taken as standard

merge_data_types <- function(df1, df2) {
  common_cols <- intersect(names(df1), names(df2))  # Find common columns
  
  for (col in common_cols) {
    if (class(df1[[col]]) != class(df2[[col]])) {
      # Convert df2 column to match df1 column type
      if (is.character(df1[[col]])) {
        df2[[col]] <- as.character(df2[[col]])
      } else if (is.numeric(df1[[col]])) {
        df2[[col]] <- as.numeric(df2[[col]])
      } else if (is.integer(df1[[col]])) {
        df2[[col]] <- as.integer(df2[[col]])
      } else if (is.factor(df1[[col]])) {
        df2[[col]] <- as.factor(df2[[col]])
      } else if (is.logical(df1[[col]])) {
        df2[[col]] <- as.logical(df2[[col]])
      } else if (inherits(df1[[col]], "Date")) {
        df2[[col]] <- as.Date(df2[[col]])
      } else if (inherits(df1[[col]], "POSIXct")) {
        df2[[col]] <- as.POSIXct(df2[[col]])
      }
    }
  }
  
  return(df2)
}
