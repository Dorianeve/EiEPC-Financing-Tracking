source("requirements/libraries.R")

# Source ---
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")
list <- read.csv("data/utilities/recipients/list_names_iati_recipients.csv", encoding = "UTF-8")

iati %<>%
  mutate(checkID = paste0(RecipientOrgName, "-",
                          RecipientOrgID, "-",
                          RecipientOrgType))

list %<>%
  mutate(checkID = paste0(RecipientOrgName, "-",
                          RecipientOrgID, "-",
                          RecipientOrgType)) %>%
  select(-c(RecipientOrgName, RecipientOrgID, RecipientOrgType))

iati %<>%
  left_join(list, by = "checkID")

iati %<>%
  mutate(RecipientOrgName = ifelse(!is.na(RecipientOrgNameNew), RecipientOrgNameNew, RecipientOrgName),
         RecipientOrgID = ifelse(!is.na(RecipientOrgIDNew), RecipientOrgIDNew, RecipientOrgID),
         RecipientOrgType = ifelse(!is.na(RecipientOrgTypeNew), RecipientOrgTypeNew, RecipientOrgType)) %>%
  select(-c(RecipientOrgNameNew, RecipientOrgIDNew, RecipientOrgTypeNew))

write.csv(iati, "data/clean/iati.csv", row.names = TRUE)
