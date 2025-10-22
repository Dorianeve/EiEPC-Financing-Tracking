source("requirements/libraries.R")
rm(list = ls())

# No scientific notation
options(scipen = 999)

# Load datasets ----
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")

# Capping 2020 in IATI to fix bug ----
iati %<>% filter(Year != 2020)

# Step 1: Identify dubious organizations
# 1a. DestinationOrganization appearing in SourceOrganization
dubious_orgs <- iati %>%
  group_by(Year, RecipientCountry) %>%
  filter(!is.na(SourceOrganization) & !is.na(DestinationOrganization)) %>%  # Handle NA explicitly
  filter(DestinationOrganization %in% SourceOrganization) %>%
  distinct(Year, RecipientCountry, DestinationOrganization) %>%
  rename(DubiousOrganization = DestinationOrganization)

# 2. Put it in a list for join
dubious_orgs <- dubious_orgs %>%
  distinct(Year, RecipientCountry, DubiousOrganization) %>%
  mutate(Dubious = TRUE) %>%
  rename(SourceOrganization = DubiousOrganization)

# 3. Join with IATI by Year, RecipientCountry,SourceOrganization
iati %<>%
  left_join(dubious_orgs, by = c( "Year", "RecipientCountry", "SourceOrganization"))

iati <- iati %>%
  mutate(
    Dubious = ifelse(
      is.na(Dubious), 
      FALSE,  # Set Dubious to FALSE if it is NA
      ifelse(
        Dubious == TRUE & DonorType == "Multilateral",
        TRUE,
        FALSE  # Set Dubious to FALSE for rows not matching the criteria
      )
    )
  )

write.csv(iati, "data/clean/iati.csv", row.names = FALSE)

