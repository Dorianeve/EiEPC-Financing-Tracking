source("requirements/libraries.R")

# Source ---
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")
fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")
correspondance <- read.csv("data/utilities/correspondance/correspondance_table.csv", encoding = "UTF-8")

new_iati <- iati %>%
  select(ReportingOrgName, ReportingOrgID) %>%
  filter(!ReportingOrgID %in% correspondance$ReportingOrgID) %>%
  unique()
new_iati

new_fts <- fts %>%
  select(SourceOrganization, SourceOrganizationID) %>%
  filter(!SourceOrganizationID %in% correspondance$SourceOrganizationID) %>%
  unique()
new_fts

write.csv(new_iati, "data/utilities/correspondance/correspondance_new_iati.csv", row.names = FALSE)
write.csv(new_fts, "data/utilities/correspondance/correspondance_new_fts.csv", row.names = FALSE)

rm(list = ls())

# Destination ---
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")
fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")
correspondance <- read.csv("data/utilities/correspondance/correspondance_table_destination.csv", encoding = "UTF-8")

new_iati <- iati %>%
  select(RecipientOrgName, RecipientOrgID, RecipientOrgType) %>%
  filter(!RecipientOrgID %in% correspondance$ReportingOrgID &
           (RecipientOrgType == 10 | RecipientOrgType == 40)) %>%
  unique()

write.csv(new_iati, "data/utilities/correspondance/correspondance_new_iati_destination.csv", row.names = FALSE)

rm(list = ls())
