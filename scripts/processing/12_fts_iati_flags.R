source("requirements/libraries.R")
source("requirements/group_flag.R")
source("config/flags_list.yml")

iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")
fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")

iati <- group_flag(iati, displacement, "FLAG_Displacement")
iati <- group_flag(iati, eie, "FLAG_EiERelated")
iati <- group_flag(iati, geographic, "FLAG_Geographic")
iati <- group_flag(iati, humanitarian, "FLAG_HumanitarianCrises")
iati <- group_flag(iati, out_school, "FLAG_OutSchool")
iati <- group_flag(iati, risk_red_mitigation, "FLAG_RiskReductionMitigation")
iati <- group_flag(iati, protection, "FLAG_Protection")
iati <- group_flag(iati, mhpss, "FLAG_MHPSS")
iati <- group_flag(iati, inclusion, "FLAG_Inclusion")
iati <- group_flag(iati, gender, "FLAG_Gender")
iati <- group_flag(iati, edu_continuity, "FLAG_EduContinuity")
iati <- group_flag(iati, school_feeding, "FLAG_SchoolFeeding")
iati <- group_flag(iati, wash, "FLAG_Wash")
iati <- group_flag(iati, learning, "FLAG_Learning")
iati <- group_flag(iati, teachers, "FLAG_Teachers")
iati <- group_flag(iati, edu_facilities, "FLAG_EduFacilities")

iati %<>%
  mutate(across(starts_with("FLAG_"), ~ as.character(.x))) %>%
  mutate(across(starts_with("FLAG_"), ~ replace_na(.x, "NO")))

fts <- group_flag(fts, displacement, "FLAG_Displacement")
fts <- group_flag(fts, eie, "FLAG_EiERelated")
fts <- group_flag(fts, geographic, "FLAG_Geographic")
fts <- group_flag(fts, humanitarian, "FLAG_HumanitarianCrises")
fts <- group_flag(fts, out_school, "FLAG_OutSchool")
fts <- group_flag(fts, risk_red_mitigation, "FLAG_RiskReductionMitigation")
fts <- group_flag(fts, protection, "FLAG_Protection")
fts <- group_flag(fts, mhpss, "FLAG_MHPSS")
fts <- group_flag(fts, inclusion, "FLAG_Inclusion")
fts <- group_flag(fts, gender, "FLAG_Gender")
fts <- group_flag(fts, edu_continuity, "FLAG_EduContinuity")
fts <- group_flag(fts, school_feeding, "FLAG_SchoolFeeding")
fts <- group_flag(fts, wash, "FLAG_Wash")
fts <- group_flag(fts, learning, "FLAG_Learning")
fts <- group_flag(fts, teachers, "FLAG_Teachers")
fts <- group_flag(fts, edu_facilities, "FLAG_EduFacilities")

fts %<>%
  mutate(across(starts_with("FLAG_"), ~ as.character(.x))) %>%
  mutate(across(starts_with("FLAG_"), ~ replace_na(.x, "NO")))

write.csv(iati, "data/clean/iati.csv", row.names = FALSE)
write.csv(fts, "data/clean/fts.csv", row.names = FALSE)

rm(list = ls())
