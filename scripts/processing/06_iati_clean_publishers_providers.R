source("requirements/libraries.R")

list <- read.csv("data/utilities/publishers/list_iati_provider_reporting.csv", encoding = "UTF-8")
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")

iati %<>%
  mutate(Year = as.character(Year)) %>% 
  mutate(across(c(RecipientCountryCode, ReportingOrgID, ReportingOrgName,
                  TransactionProviderID, TransactionProviderName),
                ~ na_if(trimws(.), ""))) %>%  # Replace empty strings with NA
  mutate(checkID = paste0(RecipientCountryCode, "-",
                          Year, "-",
                          ReportingOrgID, "-", 
                          ReportingOrgName, "-",
                          TransactionProviderID, "-",
                          TransactionProviderName))

list %<>%
  select(checkID, ReportingOrgNameRevised, ReportingOrgIDRevised, ReportingOrgTypeRevised) %>%
  filter(complete.cases(.))

iati %<>%
  left_join(list, by = "checkID", multiple = "any")

iati %<>%
  mutate(ReportingOrgID = ifelse(!is.na(ReportingOrgIDRevised), ReportingOrgIDRevised, ReportingOrgID),
         ReportingOrgName = ifelse(!is.na(ReportingOrgNameRevised), ReportingOrgNameRevised, ReportingOrgName),
         ReportingOrgType = ifelse(!is.na(ReportingOrgTypeRevised), ReportingOrgTypeRevised, ReportingOrgType))

iati %<>%
  select(-c(ReportingOrgIDRevised, ReportingOrgNameRevised, checkID, ReportingOrgTypeRevised))

write.csv(iati, "data/clean/iati.csv", row.names = FALSE)

rm(list = ls())
