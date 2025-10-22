rm(list = ls())
source("requirements/libraries.R")

path <- "data/clean/all_countries"

# Read all CSVs with all columns as character
read_as_char <- function(file) {
  read_csv(file, col_types = cols(.default = col_character()))
}

# List all CSV files
csv_files <- fs::dir_ls(path, regexp = "\\.csv$")

# Read and bind all
combined_data <- purrr::map_dfr(csv_files, read_as_char, .id = "source_file")

# Preview
glimpse(combined_data)

combined_data %<>%
  select(-c(source_file))

# Filter ECW out

write.csv(combined_data, "data/clean/complete_dataset.csv", row.names = FALSE)

rm(list = ls())
