source("requirements/libraries.R")
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")

iati %<>% select(ReportingOrgName, ReportingOrgType, ReportingOrgID) %>%
  mutate(checkID = paste0(ReportingOrgType, "-",
                          ReportingOrgID)) %>%
  distinct()

check <- read.csv("data/utilities/reportingorg type/list_reporting_type_iati.csv", encoding = "UTF-8")

iati %<>%
  filter(!checkID %in% check$checkID)

write.csv(iati, "data/utilities/reportingorg type/new_reporting_type_iati.csv", row.names = FALSE)


rm(list = ls())