source("requirements/libraries.R")

list <- read.csv("data/utilities/reportingorg type/list_reporting_type_iati.csv", encoding = "UTF-8")
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")

list %<>%
  filter(!is.na(ReportingOrgTypeRevised)) %>%
  select(ReportingOrgID, ReportingOrgTypeRevised) %>%
  unique()

iati %<>%
  left_join(list, by = "ReportingOrgID")

iati %<>%
  mutate(ReportingOrgType = ifelse(!is.na(ReportingOrgTypeRevised), ReportingOrgTypeRevised, ReportingOrgType))

iati %<>%
  select(-ReportingOrgTypeRevised)

iati <- iati %>%
  mutate(ReportingOrgType = case_when(
    ReportingOrgType == "40" ~ "Multilateral",
    ReportingOrgType == "10" ~ "Bilateral",
    ReportingOrgType == "70" ~ "Private",
    TRUE ~ "Others"
  ))

write.csv(iati, "data/clean/iati.csv", row.names = FALSE)         
         
         

         