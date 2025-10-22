source("requirements/libraries.R")
source("requirements/flag_iati.R")
source("requirements/merge_data_types.R")
source("requirements/extract_year.R")
source("requirements/normalize_to_iso.R")
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
folder_path <- "data/raw extractions"

# Get a list of all CSV files in the folder
files <- list.files(path = folder_path, pattern = "*.csv", 
                    full.names = TRUE)

# Filter files to include those containing 'iati' but exclude those containing 'food security'
iati_files <- files[grepl("iati", tolower(files)) & !grepl("food_security", tolower(files))]


# Check if there are any matching files
if (length(iati_files) > 0) {
  # Get the most recent file based on modification time
  most_recent_file <- iati_files[which.max(file.info(iati_files)$mtime)]
  # Read the most recent CSV file
  full_data <- read.csv(most_recent_file, stringsAsFactors = FALSE)
   # Display the data from the most recent file
  message(paste(most_recent_file, "loaded successfully."))
} else {
  print("No files containing 'iati' in the name were found.")
}

# extraction date column ----
extraction_date <- sub(".*raw extractions/([^_]+)_.*", "\\1", most_recent_file)

full_data %<>%
  mutate(ExtractionDate = extraction_date)


# countries filter
full_data %<>%
  filter(recipientcountry_code %in% iati_countries)

full_data %<>%
  mutate(humanitarian = ifelse(humanitarian == "", NA, humanitarian),
         humanitarian_dup = ifelse(humanitarian_dup == "", NA, humanitarian_dup))

full_data %<>%
  mutate(control = ifelse(!is.na(humanitarian_dup), humanitarian_dup, humanitarian)) %>%
  select(-c(humanitarian, humanitarian_dup)) %>%
  rename(humanitarian = control)

# Subsetting ----
## Emergency subsetting ----
# prep data for emergency subsetting
full_data %<>% mutate(title_narrative = stri_trans_general(title_narrative, "Latin-ASCII"),
                      description_narrative = stri_trans_general(description_narrative, "Latin-ASCII"))

# Create a vector of all search terms, without accents or special characters
search_terms <- c(
  "humanitarian", "humanitaire", "humanitar", "crisis", "crise", "krise", "crises", "emergency", "urgence",
  "disaster", "desastre", "emergencies", "deplacement", "resilience", "conflict", "conflit", "drought", "secheresse",
  "vulnerable", "risk", "risque", "closure", "cloture", "drop out", "abandon", "resilient", "violence", "attacks",
  "attaque", "idp", "refugees", "refugies", "deplaces", "host", "hote", "marginalised", "accueil", "out-of-school",
  "out of school", "non scolarises", "returnees", "eie", "esu", "preparedness", "preparation", "school feeding",
  "alimentation scolaire", "psychological", "psychologic", "psychosocial", "catch-up", "rattrapage", "school", "ecole",
  "protection", "protective", "protecteur", "safe", "sur", "safety", "securite", "insertion", "accelerated", "accelere",
  "adapted", "adapte", "inclusive", "inclusif", "response", "barriers", "barriere", "mitigation", "continuity",
  "continuation", "GBV", "violence", "WASH", "assainissement", "adaptation", "DRR", "prevention", "Afar", "Tigray",
  "Amhara", "BG", "Oromia", "Somali", "Benishangul-Gumuz", "Gambella", "Lake Chad", "Wadi Fira", "Biltine", "Dar Tama",
  "Iriba", "Megri", "Sila", "Djourf Al Ahmar", "Kimiti", "Ouaddaand", "Abdi", "Assoungha", "Ouara", "Nord-Kivu",
  "Sud-Kivu", "Ituri", "Maindombe", "North East", "Bomo", "Borno", "Yobe", "Adamawa", "Gombe"
)

# Create a single regex pattern with the terms, separated by `|`
pattern <- paste0("\\b(", paste(search_terms, collapse = "|"), ")\\b")

# Flag the dataset using the updated pattern "AidCrisis"
full_data <- full_data %>%
  mutate(
    AidCrisis = ifelse(
      (grepl("t", humanitarian, ignore.case = TRUE) | 
         sector_code == "72012" |
         (grepl(pattern, title_narrative, ignore.case = TRUE) | 
         grepl(pattern, description_narrative, ignore.case = TRUE))),
      "YES", "NO"
    )
  )

full_data <- full_data %>%
  mutate(
    AidEducation = "YES",
    AidHumanitarian = "NO")

## Retain the necessary codes ----
# This should not be necessary in the new transaction breakdown extraction
codes <- c('11110', '11120', '11130', '11182', '11220', '11230', '11231', '11232', '11240', '11250', '11260', 
           '11320', '11321', '11322', '11330', '11420', '11430', '111', '112', '113', '114', 
           '72012', '43010', '43081', '51010', '52010')


full_data %<>% filter(sector_code %in% codes)

# Merging with clean food security/education extraction ----
full_data_fs <- read.csv("data/clean/iati_premerge/full_food_security.csv", encoding = "UTF-8")

# Ensure full_data_fs has only the columns from full_data
full_data_fs <- full_data_fs %>%
  select(all_of(names(full_data)))

full_data_fs <- merge_data_types(full_data, full_data_fs)

# Bind the two data frames
full_data <- bind_rows(full_data, full_data_fs)

# ## Clean OrgNames ----
full_data %<>%
  mutate(
    reportingorg_narrative = sub("^(EN:|DE:|FR:) ?", "", reportingorg_narrative),
    providerorg_narrative = sub("^(EN:|DE:|FR:) ?", "", providerorg_narrative),
    receiverorg_narrative = sub("^(EN:|DE:|FR:) ?", "", receiverorg_narrative)
  )
# 
# # Parent vs child in reporting org and provider org ----
# excel_file <- "data/utilities/parent_child_orgs_iati.xlsx"
# 
# # Read the 'parent_child_orgs' sheet
# parent_orgs <- read_excel(excel_file, sheet = "parent_child_orgs")
# # Read the 'org_type' sheet
# org_type <- read_excel(excel_file, sheet = "org_type")
# 
# rm(excel_file)
# 
# full_data %<>%
#   left_join(parent_orgs, c("providerorg_narrative" = "Child"))
# 
# full_data <- full_data %>%
#    mutate(providerorg_narrative = ifelse(!is.na(Parent), Parent, providerorg_narrative),
#           providerorg_narrative = ifelse(providerorg_narrative == "", NA, providerorg_narrative)) %>%
#    select(-Parent)
# 
# rm(parent_orgs)
# 
# full_data %<>%
#   mutate(providerorg_ref = ifelse(providerorg_narrative == reportingorg_narrative, reportingorg_ref,
#                                   providerorg_ref))
# 
# 
# ## ReportingOrgType "Multilateral" (40) and "Bilateral" (10) ----
# 
# # added OCHA as Pooled Funds were kept under 22 NGO code
# # added EC as it was not tagged in Multilateral
# full_data %<>%
#   left_join(org_type, by = "reportingorg_ref") %>%  # Adds the 'Type' column
#   mutate(ReportingOrgType = case_when(
#     reportingorg_type == "40" ~ "Multilateral",
#     reportingorg_type == "10" ~ "Bilateral",
#     !is.na(type) ~ type,  # Use 'Type' from org_type if it exists
#     TRUE ~ "Others"
#   )) %>%
#   select(-type)  # Remove temporary 'Type' column after mapping
# rm(org_type)


# Harmonize with ISO names and standards ----
iso <- read.csv("data/utilities/iso_codes.csv", encoding = "UTF-")

## Country names ----
full_data %<>%
  left_join(iso, by = c("recipientcountry_code" = "ISO2")) %>%
  rename(RecipientCountry = Name_fts) %>%
  select(-c(ID_fts, Pcode_fts, IsRegion))
rm(iso)

full_data <- full_data %>% distinct()


## Clean columns ----
full_data <- full_data %>%
  rename(ID = LinkTransaction,
         ActivityID = iatiidentifier,
         TransactionDate = transactiondate_isodate,
         ReportingOrgID = reportingorg_ref,
         ReportingOrgName = reportingorg_narrative,
         ReportingOrgType = reportingorg_type,
         TransactionProviderID = providerorg_ref,
         TransactionProviderName = providerorg_narrative,
         TransactionProviderType = providerorg_type,
         RecipientOrgID = receiverorg_ref,
         RecipientOrgName = receiverorg_narrative,
         RecipientOrgType = receiverorg_type,
         AmountUSD = value_usd,
         PercentageUsed = percentage_used,
         HumanitarianFlag = humanitarian,
         ActivityName = title_narrative,
         ActivityDescription = description_narrative,
         RecipientCountryCode = recipientcountry_code,
         RecipientRegionCode = recipientregion_code,
         RecipientRegionName = recipientregion_codename,
         SectorCode = sector_code,
         SectorName = sector_codename,
         TransactionTypeCode = transactiontype_code,
         TransactionTypeName = transactiontype_codename,
         FinancialTypeCode = defaultfinancetype_code,
         FinancialTypeName = defaultfinancetype_codename) %>%
  mutate(Dataset = "IATI") %>%
  mutate(Year = extract_year(TransactionDate))

full_data <- full_data %>%
  select(Dataset,         
         ID, 
         ActivityID,
         TransactionDate,
         Year,
         ReportingOrgID,
         ReportingOrgName,
         ReportingOrgType,
         TransactionProviderID,
         TransactionProviderName,
         TransactionProviderType,
         RecipientOrgID,
         RecipientOrgName,
         RecipientOrgType,
         AmountUSD,
         PercentageUsed,
         SectorCode,
         SectorName,
         HumanitarianFlag,
         ActivityID,
         ActivityName,
         ActivityDescription,
         RecipientCountry,
         RecipientCountryCode,
         ISO3,
         RecipientRegionName,
         RecipientRegionCode,
         TransactionTypeCode,
         TransactionTypeName,
         FinancialTypeCode,
         FinancialTypeName,
         AidCrisis,
         AidEducation,
         AidHumanitarian,
         value,
         ExtractionDate)

# Clean SectorCode Classification
full_data <- full_data %>%
  mutate(Sector = case_when(
    grepl("43010", SectorCode) ~ "Multisector",
    grepl("43081", SectorCode) ~ "Multisector (with Education)",
    grepl("51010", SectorCode) ~ "General budget support",
    grepl("52010", SectorCode) ~ "Food assistance (with Education)",
    TRUE ~ "Education"))

full_data <- full_data %>%
  mutate(
    Date = TransactionDate,
    TransactionDate = normalize_to_iso(TransactionDate),   # parse "YYYY-MM-DD"
  )

options(digits = 15)  # Adjust the number of digits as needed
# No scientific notation
options(scipen = 999)

# Assignment ID ----
full_data %<>% mutate(AssignedID = paste0(ActivityID, "_", 
                                         ReportingOrgID, "_", 
                                         RecipientCountryCode, "_",
                                         SectorCode, "_",
                                         RecipientOrgName, "_",
                                         TransactionDate, "_",
                                         value))
# Save full complete dataset ----
write.csv(full_data, "data/clean/iati.csv", row.names = FALSE)


