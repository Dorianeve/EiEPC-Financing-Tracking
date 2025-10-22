source("requirements/libraries.R")
rm(list = ls())

iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")


# Provider / transaction /reportingortype
# Reporting / Provider Verification ----
iati <- iati %>%
  mutate(Year = as.character(Year),
         ReportingOrgType = as.character(ReportingOrgType),
         TransactionProviderType = as.character(TransactionProviderType)) %>% 
  select(RecipientCountryCode, Year, ReportingOrgID, ReportingOrgName, ReportingOrgType,
         TransactionProviderID, TransactionProviderName, TransactionProviderType) %>%
  mutate_all(~ na_if(., "")) %>%
  distinct() %>%
  filter(TransactionProviderName != ReportingOrgName |
           TransactionProviderID != ReportingOrgID |
           ((TransactionProviderName == ReportingOrgName) & is.na(TransactionProviderType)))

iati %<>% 
  mutate(checkID = paste0(RecipientCountryCode, "-",
                          Year, "-",
                          ReportingOrgID, "-", 
                          ReportingOrgName, "-",
                          TransactionProviderID, "-",
                          TransactionProviderName),
         ReportingOrgNameRevised = "",
         ReportingOrgIDRevised = "",
         ReportingOrgTypeRevised = "")

check <- read.csv("data/utilities/publishers/list_iati_provider_reporting.csv", encoding = "UTF-8")

iati %<>%
  filter(!checkID %in% check$checkID)

# For checking transaction provider and reporting org
write.csv(iati, "data/utilities/publishers/new_iati_provider_reporting.csv", row.names = FALSE)

rm(list = ls())
