source("requirements/libraries.R")

# Source ---
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")
fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")

list <- read.csv("data/utilities/recipients/list_names_iati_recipients.csv", encoding = "UTF-8")

new_iati <- iati %>% 
  select(RecipientOrgName, RecipientOrgID, RecipientOrgType) %>%
  filter(!RecipientOrgID %in% list$RecipientOrgID &
           (RecipientOrgType == 10 |
           RecipientOrgType == 40 |
           grepl("UNHCR|UNICEF|WFP|FAO|UN|WHO|UNWOMEN|UNDP|UNITED NATIONS", RecipientOrgName, ignore.case = TRUE)))%>%
  unique()

new_iati %<>%
  filter(!RecipientOrgName %in% list$RecipientOrgName)

write.csv(new_iati, "data/utilities/recipients/names_iati_new_recipients.csv", row.names = FALSE)

list <- read.csv("data/utilities/recipients/list_names_fts_recipients.csv", encoding = "UTF-8")

new_fts <- fts %>%
  select(DestinationOrganization, DestinationOrganizationID) %>%
  unique()

new_fts %<>%
  filter(!DestinationOrganizationID %in% list$DestinationOrganizationID)

write.csv(new_fts, "data/utilities/recipients/names_fts_new_recipients.csv", row.names = FALSE)


rm(list = ls())
