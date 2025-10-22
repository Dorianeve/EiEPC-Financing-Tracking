source("requirements/libraries.R")
source("config/extraction_config.yml")

# prep saving env
# Define the directory path
dir_path <- "data/clean/"

# Check if directory exists; if not, create it
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}

# Load latest file ----
# Define the folder path containing the files
# folder_path <- "data/raw extractions" # old_method
folder_path <- file.path("data/raw extractions/fts", paste(countries, collapse = "_")) # new method after 10th may

# Get a list of all CSV files in the folder
files <- list.files(path = folder_path, pattern = "*.csv", 
                    full.names = TRUE)

# Filter files to only include those containing 'iati' in their name
fts_files <- files[grepl("fts", tolower(files))]

# Check if there are any matching files
if (length(fts_files) > 0) {
  # Get the most recent file based on modification time
  most_recent_file <- fts_files[which.max(file.info(fts_files)$mtime)]
  # Read the most recent CSV file
  full_data <- read.csv(most_recent_file, stringsAsFactors = FALSE)
  # Display the data from the most recent file
  message(paste(most_recent_file, "loaded successfully."))
} else {
  print("No files containing 'iati' in the name were found.")
}

# extraction date column ----
extraction_date <- sub(".*/([0-9]{4}-[0-9]{2}-[0-9]{2})_.*", "\\1", most_recent_file)

full_data %<>%
  mutate(ExtractionDate = extraction_date)

colnames(full_data) <- gsub(" ", "", colnames(full_data))

# ID present in "parent ID" ----
parentIDs <- full_data$ParentFlowId

secondary_flows <- full_data %>% 
  filter(ID %in% parentIDs)

print(paste0(nrow(secondary_flows), " secondary flows found in fts."))

# This is muted for the analysis. But it can be considered.
# # removing parentIDs
#  full_data <- full_data %>% 
#    filter(!ID %in% parentIDs)

rm(parentIDs, secondary_flows)

# Filter out OnBoundary != "shared" (FTS rule) ----
full_data %<>%
  filter(OnBoundary != "shared")

# Flag AidHumanitarian / AidEducation / AidCrisis
full_data %<>%
  mutate(AidHumanitarian = "YES",
         AidEducation = "YES",
         AidCrisis = "YES")

full_data %<>%
  mutate(ActivityName = "",
         HumanitarianFlag = "")

full_data <- full_data %>%
  rename(Sector = GlobalCluster,
         SectorBehavior = GlobalClusterBehavior,
         ActivityDescription = Description,
         ReportingOrgName = ReportingOrg) %>%
  mutate(Dataset = "FTS")

# Assignment ID ----
full_data %<>% mutate(AssignedID = paste0(ID, "_", 
                                          SourceOrganizationID, "_", 
                                          ISO3, "_",
                                          Sector, "_",
                                          DestinationOrganizationID, "_",
                                          Date, "_",
                                          AmountUSD))

# Save ----
write.csv(full_data, "data/clean/fts.csv", row.names = FALSE)

rm(list = ls())

