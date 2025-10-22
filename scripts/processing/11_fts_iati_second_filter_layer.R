source("requirements/libraries.R")
rm(list = ls())

iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")
fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")

# Filter reporting organization
iati %<>% filter(ReportingOrgType != "Others" & ReportingOrgType != "Private")
fts %<>% filter(DonorType != "Others" & DonorType != "Private"  )

write.csv(iati, "data/clean/iati.csv", row.names = FALSE)
write.csv(fts, "data/clean/fts.csv", row.names = FALSE)

rm(list = ls())
