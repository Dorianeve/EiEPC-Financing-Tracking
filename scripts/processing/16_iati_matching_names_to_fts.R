source("requirements/libraries.R")

# Source ---
iati <- read.csv("data/clean/iati.csv", encoding = "UTF-8")
fts <- read.csv("data/clean/fts.csv", encoding = "UTF-8")
correspondance <- read.csv("data/utilities/correspondance/correspondance_table.csv", encoding = "UTF-8")

correspondance %<>%
  mutate(SourceOrganization = ifelse(SourceOrganization == "", NA, SourceOrganization),
         ReportingOrgID = ifelse(ReportingOrgID == "", NA, ReportingOrgID),
         ReportingOrgName = ifelse(ReportingOrgName == "", NA, ReportingOrgName)) %>%
  drop_na()

correspondance %<>%
  select(-c(ReportingOrgName))

iati %<>%
  left_join(correspondance, by = "ReportingOrgID")

iati %<>%
  mutate(SourceOrganization = ifelse(!is.na(SourceOrganization), SourceOrganization, ReportingOrgName),
         SourceOrganizationID = ifelse(!is.na(SourceOrganizationID), SourceOrganizationID, ReportingOrgID))

correspondance %<>%
  rename(RecipientOrgID = ReportingOrgID,
         DestinationOrganization = SourceOrganization,
         DestinationOrganizationIDiati = SourceOrganizationID)

iati %<>%
  left_join(correspondance, by = "RecipientOrgID", multiple = "any")

iati %<>%
  mutate(DestinationOrganization = ifelse(!is.na(DestinationOrganization), DestinationOrganization, RecipientOrgName),
         DestinationOrganizationIDiati = ifelse(!is.na(DestinationOrganizationIDiati), DestinationOrganizationIDiati, RecipientOrgID))

check <- iati %>%
  select(ReportingOrgName, SourceOrganization,
         TransactionProviderName,
         RecipientOrgName, DestinationOrganization) %>%
  unique()

write.csv(check, "data/utilities/matched names/matched_names_iati.csv", row.names = FALSE)

# Clean merged IATI for FTS structure ----
iati %<>%
  rename(DonorType = ReportingOrgType,
         DestinationOrgType = RecipientOrgType)


iati <- iati %>%
  select(Dataset,
         AssignedID,
         ActivityID,
         ID,
         Date,
         Year,
         DonorType,
         SourceOrganizationID,
         SourceOrganization,
         TransactionProviderID,
         TransactionProviderName,
         TransactionProviderType,
         ReportingOrgName,
         ReportingOrgID,
         DestinationOrganization,
         DestinationOrganizationIDiati,
         DestinationOrgType,
         AmountUSD,
         RecipientCountry,
         ISO3,
         SectorName,
         SectorCode,
         Sector,
         ActivityName,
         ActivityDescription,
         HumanitarianFlag,
         TransactionTypeCode,
         TransactionTypeName,
         FinancialTypeCode,
         FinancialTypeName,
         AidCrisis,
         AidEducation,
         AidHumanitarian,
         FLAG_Displacement,
         FLAG_EiERelated,
         FLAG_Geographic,
         FLAG_HumanitarianCrises,
         FLAG_OutSchool,
         FLAG_RiskReductionMitigation,
         FLAG_Protection,
         FLAG_MHPSS,
         FLAG_Inclusion,
         FLAG_Gender,
         FLAG_EduContinuity,
         FLAG_SchoolFeeding,
         FLAG_Wash,
         FLAG_Learning,
         FLAG_Teachers,
         FLAG_EduFacilities,
         ExtractionDate)


write.csv(iati, "data/clean/iati.csv", row.names = FALSE)

