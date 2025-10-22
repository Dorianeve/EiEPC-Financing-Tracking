source("requirements/libraries.R")
rm(list = ls())

iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")
fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")

# Filter transaction type (Disbursement)
iati %<>% filter(TransactionTypeCode == 3)

# Filter sectors (necessary in IATI, might be redundant in FTS as it is done in extraction)
iati %<>% filter(Sector == "Education" |
                    Sector == "Multisector (with Education)" | 
                   Sector == "Food assistance (with Education)")
fts %<>% filter(Sector == "Education" |
         Sector == "Multisector (with Education)")

write.csv(iati, "data/clean/iati.csv", row.names = FALSE)
write.csv(fts, "data/clean/fts.csv", row.names = FALSE)

rm(list = ls())
