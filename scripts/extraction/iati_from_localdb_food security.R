source("requirements/libraries.R")
source("config/extraction_config.yml")

# prep saving env
# Define the directory path
dir_path <- "data/raw extractions/"

# Check if directory exists; if not, create it
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}

db_file <- db_path

con <- dbConnect(RSQLite::SQLite(), db_file)

# Complete (does not need merging)
# iteration date:
# 2025.02.06
# 2025.04.01
# 2025.10.01

# collapse vector into a SQL-safe string
sector_list <- paste0("'", paste(iati_fs_sectorcode, collapse = "', '"), "'")

query <- paste0("
  SELECT 
    tb.*,
    tr.*,
    a.reportingorg_type, 
    a.reportingorg_narrative,
    a.humanitarian, 
    a.title_narrative, 
    a.description, 
    a.location,
    a.defaultfinancetype_code, 
    a.defaultfinancetype_codename
  FROM transaction_breakdown tb
  JOIN trans tr
    ON tb._link_transaction = tr._link
  JOIN activity a
    ON tb._link_activity = a._link
  WHERE 
    tb.sector_code IN (", sector_list, ")
    AND tb.transactiondate_isodate > '", iati_start_range, "'
    AND tb.transactiondate_isodate < '", iati_end_range, "';
")

data <- dbGetQuery(con, query)

dbDisconnect(con)

# this is transaction not broken down but it contains necessary info for merging
df <- data 

colnames(df)[duplicated(colnames(df))] <- paste0(colnames(df)[duplicated(colnames(df))], "_dup")

# df %<>% select(all_of(names(.)[!duplicated(names(.))]))

df %<>% 
  rename(LinkActivity = `_link_activity`,
         LinkTransaction = `_link_transaction`)

df <- df %>%
  select(-matches(".*_dup$"), humanitarian_dup)  # Remove _dup columns except humanitarian_dup

# df %<>%
#   mutate(ExtractionDate = today())

write.csv(df, paste0("data/raw extractions/", today(),"_datasette_iati_food_security.csv"), row.names = FALSE)

rm(list = ls())

