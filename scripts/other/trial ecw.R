source("requirements/libraries.R")
source("extraction_config.yml")

# prep saving env
# Define the directory path
dir_path <- "data/raw_extractions/"

# Check if directory exists; if not, create it
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}

con <- dbConnect(RSQLite::SQLite(), "data/local db/iati.sqlite")

# Complete (does not need merging)
# iteration date:
# 2025.02.06
data <- dbGetQuery(con, "SELECT t.*
                    FROM trans t
                   WHERE t.reportingorg_ref = 'XM-OCHA-HPC8773';")

dbDisconnect(con)

df <- data
