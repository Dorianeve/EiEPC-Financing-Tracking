source("requirements/libraries.R")
source("config/extraction_config.yml")
today <- today()

# Create folder name (as string)
folder_name <- paste0("data/clean/", paste(countries, collapse = " "), "/", today)
overall_folder <- "data/clean/all_countries/"

# Create the folder if it doesn't exist
if (!dir.exists(folder_name)) {
  dir.create(folder_name, recursive = TRUE)
}

# Create the folder if it doesn't exist
if (!dir.exists(overall_folder)) {
  dir.create(overall_folder, recursive = TRUE)
}

# No scientific notation
options(scipen = 999)

# Load datasets ----
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")
fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")

# Capping 2020 in IATI to fix bug ----
iati %<>% filter(Year != 2020)

# Prep datasets for merging
# Rounding up IATI
iati$AmountUSD <- ceiling(iati$AmountUSD)

missing_in_iati <- setdiff(names(fts), names(iati))
missing_in_fts <- setdiff(names(iati), names(fts))

# Add missing columns to iati
for (col in missing_in_iati) {
  iati[[col]] <- NA
}
# Add missing columns to fts
for (col in missing_in_fts) {
  fts[[col]] <- NA
}
# Binding both datasets for analysis
df <- rbind(iati, fts)

# # Load manual flags ----
# # Step 1: Get all sheet names from the Excel file
# file_path <- "data/utilities/manual_flags.xlsx"  # Path to your Excel file
# sheet_names <- excel_sheets(file_path)  # Get all sheet names
# 
# # Step 2: Define a function to read each sheet and return a dataframe
# read_sheet <- function(sheet) {
#   read_excel(file_path, sheet = sheet)  # Read each sheet
# }
# 
# # Step 3: Iterate over all sheets, read them, and combine (rbind) them into one dataframe
# combined_data <- lapply(sheet_names, read_sheet) %>% 
#   bind_rows()  # Combine all sheets by row
# 
# # Function to normalize IDs
# normalize_string <- function(x) {
#   x %>%
#     str_to_lower() %>%
#     str_replace_all("[[:space:][:punct:]]+", "") %>%
#     str_trim()
# }
# 
# # Clean relevant columns in combined_data
# combined_data %<>%
#   mutate(
#     ID_fts_clean = normalize_string(trimws(ID_fts)),
#     ID_iati_clean = normalize_string(trimws(ID_iati)),
#     Decision = trimws(Decision)
#   )
# 
# # Assign ID_delete based on Decision
# combined_data %<>%
#   mutate(ID_delete_clean = case_when(
#     Decision == "IATI" ~ ID_fts_clean,
#     Decision == "FTS" ~ ID_iati_clean,
#     Decision == "Delete" & is.na(ID_fts_clean) ~ ID_iati_clean,
#     Decision == "Delete" & is.na(ID_iati_clean) ~ ID_fts_clean,
#     TRUE ~ NA_character_
#   ))
# 
# # Clean df AssignedID
# df %<>%
#   mutate(
#     AssignedID = trimws(AssignedID),
#     AssignedID_clean = normalize_string(AssignedID)
#   )
# 
# # Flag duplicates using cleaned IDs
# df %<>%
#   mutate(Duplicate = case_when(
#     AssignedID_clean %in% combined_data$ID_fts_clean ~ "Yes",
#     AssignedID_clean %in% combined_data$ID_iati_clean ~ "Yes",
#     TRUE ~ "No"
#   ))
# 
# # Update AidHumanitarian for selected IATI transactions
# df %<>%
#   mutate(AidHumanitarian = case_when(
#     AssignedID_clean %in% combined_data$ID_iati_clean[combined_data$Decision == "IATI"] ~ "YES",
#     TRUE ~ AidHumanitarian
#   ))
# 
# # Flag entries to delete
# df %<>%
#   mutate(ToDelete = case_when(
#     AssignedID_clean %in% combined_data$ID_delete_clean ~ "Yes",
#     TRUE ~ "No"
#   ))
# 
# # Reshape combined_data to long format with clean AssignedIDs
# combined_data_long <- combined_data %>%
#   pivot_longer(cols = c(ID_iati_clean, ID_fts_clean), names_to = "Source", values_to = "AssignedID_clean") %>%
#   select(AssignedID_clean, Verification_type) %>%
#   distinct()
# 
# # Join VerificationType
# df %<>%
#   left_join(combined_data_long, by = "AssignedID_clean") %>%
#   rename(VerificationType = Verification_type)
# 
# # Optional: remove *_clean columns before saving
# df %<>% select(-AssignedID_clean)



# Clean dubious for FTS
df %<>%
  mutate(Dubious = ifelse(is.na(Dubious), FALSE, Dubious))


# Create columns fo easy export as we do not flag to delete anymore
df %<>%
  mutate(Duplicate = "No",
         ToDelete = "No",
         VerificationType = NA)


df %<>%
  select(Dataset, AssignedID, ActivityID, ID,
         Date, Year,
         SourceOrganization, SourceOrganization, DonorType,
         DestinationOrganization, DestinationOrganizationIDiati, DestinationOrgType,
         AmountUSD, RecipientCountry, ISO3, Sector, SectorName, SectorCode,
         ActivityName, ActivityDescription, HumanitarianFlag, TransactionTypeCode,
         TransactionTypeName, FinancialTypeCode, FinancialTypeName,
         AidEducation, AidCrisis, AidHumanitarian, FLAG_Protection,
         FLAG_MHPSS, FLAG_Gender, FLAG_EduContinuity, FLAG_Wash,
         FLAG_Teachers, FLAG_HumanitarianCrises, FLAG_Inclusion,
         FLAG_Geographic, FLAG_EduFacilities, FLAG_RiskReductionMitigation,
         FLAG_Displacement, FLAG_EiERelated, FLAG_OutSchool,
         FLAG_SchoolFeeding, FLAG_EiERelated, FLAG_Learning,
         Dubious, Duplicate, ToDelete, VerificationType,
         ParentFlowId, ChildFlowIds, ContributionType, OriginalAmount, OriginalCurrency,
         ExchangeRate, FlowType, Method, GHO, Cluster, ClusterBehavior, SectorBehavior, 
         RecipientCountryBehavior, DestinationCountryID, DestinationCountry,
         OnBoundary,TransactionProviderID, TransactionProviderName, TransactionProviderType,
         ReportingOrgName, ReportingOrgID, ExtractionDate)


# ECW patch: retaining only ECW from IATI
df %<>%
  filter(!(SourceOrganization == "Education Cannot Wait Fund" & Dataset == "FTS"))

# Re-naming ----
df %<>%
  # source org
  mutate(
    SourceOrganization = gsub(", Government of", "", SourceOrganization),
    SourceOrganization = case_when(
      grepl("Deutsche Gesellschaft für Internationale Zusammenarbeit", SourceOrganization) ~ "Germany",
      grepl("DEVCO", SourceOrganization) ~ "European Union",
      grepl("European Commission's Humanitarian Aid", SourceOrganization) ~ "European Union",
      SourceOrganization == "European Commission" ~ "European Union",
      SourceOrganization == "European External Action Service" ~ "European Union",
      TRUE ~ SourceOrganization
    )
  ) %>%
  # sectorname
  mutate(
    SectorName = case_when(
      grepl("Upper Secondary Education", SectorName) ~ "Upper Secondary Education",
      TRUE ~ SectorName
    )
  )



for (code in countries) {
  df_country <- df %>% filter(ISO3 == code)
  filename <- paste0(folder_name, "/", code," dataset.csv")
  write.csv(df_country, filename, row.names = FALSE)
}


for (code in countries) {
  df_country <- df %>% filter(ISO3 == code)
  filename <- paste0(overall_folder, "/", code," dataset.csv")
  write.csv(df_country, filename, row.names = FALSE)
}

# Create the workbook
wb <- createWorkbook()
# Add a worksheet
addWorksheet(wb, "dataset")
# Write the data
writeData(wb, "dataset", df)
# Save to file with today's date
saveWorkbook(wb, paste0(folder_name, "/", today(), " dataset.xlsx"), overwrite = TRUE)

rm(list = ls())
