source("requirements/libraries.R")

fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")

list <- read.csv("data/utilities/revised list/list_fts_revised_names_type.csv", encoding = "UTF-8")

list %<>%
  select(-c(SourceOrganization))

fts %<>%
  left_join(list, by = "SourceOrganizationID")

fts <- fts %>%
  mutate(SourceOrganization = ifelse(!is.na(SourceOrganizationRevised), SourceOrganizationRevised, SourceOrganization)) %>%
  mutate(SourceOrganizationID = ifelse(!is.na(SourceOrganizationIDRevised), SourceOrganizationIDRevised, SourceOrganizationID)) %>%
  mutate(DonorType = ifelse(!is.na(DonorTypeRevised), DonorTypeRevised, DonorType)) %>%
  select(-c(SourceOrganizationRevised, SourceOrganizationIDRevised, DonorTypeRevised))

fts %<>%
  mutate(DonorType = case_when(
    DonorType == "Governments" ~ "Bilateral",
    DonorType %in% c("Multilateral Organizations", "Pooled Funds") ~ "Multilateral",
    DonorType == "Private Organizations" ~ "Private",
    TRUE ~ "Others"
  ))

write.csv(fts, "data/clean/fts.csv", row.names = FALSE)

rm(list = ls())
