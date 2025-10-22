# List of required packages
required_packages <- c(
  "dotenv", "httr", "tibble", "tidyverse", 
  "dplyr", "ggplot2", "DT", 
  "plotly", "viridis", "readr", "progress",
  "countrycode", "writexl", "lubridate", "openxlsx", "openxlsx2",
  "stringr", "scales", "readxl", "ggrepel",
  "jsonlite", "stringi", "urltools", "magrittr", "VennDiagram", "ggforce",
  "here", "yaml", "DBI", "RSQLite", "fs", "purrr"
)

# Function to check, install if necessary, and load packages
load_libraries <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE)) {
      install.packages(pkg, dependencies = TRUE)
      library(pkg, character.only = TRUE)
    }
  }
}

# Load all required packages
load_libraries(required_packages)
