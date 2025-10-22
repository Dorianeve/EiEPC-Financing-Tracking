source("requirements/libraries.R")
source("requirements/flag_iati.R")
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

# Filter files to only include those containing 'iati' in their name
iati_files <- files[grepl("food_security", tolower(files))]

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
## Education subsetting ----

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

eie <- c("school", "ecole", "school feeding", "alimentation scolaire", "out-of-school", "out of school",
         "scolarises")

full_data <- flag_iati(full_data, eie, "AidEducation")
full_data <- flag_iati(full_data, eie, "FLAG_Humanitarian")

# Flag "AidEducation", which is the total humanitarian, EIEPC, development
full_data %<>%
  mutate(AidHumanitarian = "NO")

# Flag "AidCrisis" utilising FLAG and humanitarian columns
full_data %<>%
  mutate(AidCrisis = case_when(
    (grepl("t", humanitarian, ignore.case = TRUE) | 
       FLAG_Humanitarian == "YES") ~ "YES",
     TRUE ~ "NO"
  ))

## Filter Education and Crisis ----
full_data %<>%
  filter(AidEducation == "YES" &
           AidCrisis == "YES")

## Retain the necessary codes ----
# This should not be necessary in the new transaction breakdown extraction
codes <- c('11110', '11120', '11130', '11182', '11220', '11230', '11231', '11232', '11240', '11250', '11260', 
           '11320', '11321', '11322', '11330', '11420', '11430', '111', '112', '113', '114', 
           '72012', '43010', '43081', '51010', '52010')

full_data %<>% filter(sector_code %in% codes)

full_data <- full_data %>% distinct()

write.csv(full_data, "data/clean/iati_premerge/full_food_security.csv", row.names = FALSE)

