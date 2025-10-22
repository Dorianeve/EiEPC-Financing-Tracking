source("requirements/libraries.R")

fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")

list <- read.csv("data/utilities/sourceorg/list_names_fts.csv", encoding = "UTF-8")

new_names <- fts %>%
  select(SourceOrganization, SourceOrganizationID, DonorType) %>%
  filter(!SourceOrganizationID %in% list$SourceOrganizationID) %>%
  unique()

write.csv(new_names, "data/utilities/sourceorg/new_names_fts.csv", row.names = FALSE)


rm(list = ls())


