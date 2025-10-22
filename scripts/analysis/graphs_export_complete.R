rm(list = ls())
source("requirements/libraries.R")
source("config/extraction_config.yml")

df <- read.csv("data/clean/complete_dataset.csv", encoding = "UTF-8")

# Optional: check that GHO is now present
unique(df$ISO3)

df %<>%
  mutate(Date = as.Date(Date),
         Year = as.numeric(Year),
         AmountUSD = as.numeric(AmountUSD))


# total_funding ----
total_funding <- df %>%
  filter(ToDelete != "Yes") %>%
  group_by(Dataset, Year) %>%
  summarise(Total = sum(AmountUSD, na.rm = TRUE)) %>%
  pivot_wider(names_from = Dataset, values_from = Total)
total_funding

# funding_country ----
funding_country <- df %>%
  filter(ToDelete != "Yes") %>%
  group_by(Dataset, RecipientCountry) %>%
  summarise(Total = sum(AmountUSD, na.rm = TRUE)) %>%
  pivot_wider(names_from = Dataset, values_from = Total)
funding_country

# total_extracted ----
total_extracted <- df %>%
  group_by(Dataset) %>%
  summarise(Total = sum(AmountUSD, na.rm = TRUE))
total_extracted

# donor_overlap ----
donor_overlap <- df %>%
  filter(ToDelete != "Yes") %>%
  group_by(Dataset, SourceOrganization, Duplicate) %>%
  summarise(Total = sum(AmountUSD, na.rm = TRUE)) %>%
  pivot_wider(names_from = Dataset, values_from = Total) %>%
  mutate(Overlap = ifelse(Duplicate == "Yes", FTS, NA),
         Overlap = ifelse(Duplicate == "Yes" & is.na(FTS), IATI, Overlap),
         FTS = ifelse(!is.na(Overlap), NA, FTS),
         IATI = ifelse(!is.na(Overlap), NA, IATI)) %>%
  select(-c(Duplicate)) %>%
  filter(is.na(Overlap)) %>%
  select(-c(Overlap))
donor_overlap

# overlap ----
overlap <- df %>%
  filter(ToDelete != "Yes") %>%
  group_by(Dataset, SourceOrganization, Duplicate) %>%
  summarise(Total = sum(AmountUSD, na.rm = TRUE)) %>%
  pivot_wider(names_from = Dataset, values_from = Total) %>%
  mutate(Overlap = ifelse(Duplicate == "Yes", FTS, NA),
         Overlap = ifelse(Duplicate == "Yes" & is.na(FTS), IATI, Overlap),
         FTS = ifelse(!is.na(Overlap), NA, FTS),
         IATI = ifelse(!is.na(Overlap), NA, IATI)) %>%
  select(-c(Duplicate)) %>%
  filter(!is.na(Overlap))%>%
  select(-c(FTS, IATI))
overlap

# donor_overlap ----
donor_overlap %<>%
  left_join(overlap, by = "SourceOrganization")
donor_overlap

rm(overlap)

# donors_country ----
donors_country <- df %>%
  filter(ToDelete != "Yes") %>%
  group_by(SourceOrganization, RecipientCountry) %>%
  summarise(Total = sum(AmountUSD, na.rm = TRUE)) %>%
  mutate(`Step from` = 1,
         `Step to` = 2)
donors_country

# modify flag column ----
df %<>%
  mutate(Flag = case_when(
    FLAG_Protection == "YES" ~ "Protection",
    FLAG_MHPSS  == "YES" ~ "MHPSS",
    FLAG_Gender  == "YES" ~ "Gender",
    FLAG_EduContinuity  == "YES" ~ "Education Continuity",
    FLAG_Wash == "YES" ~ "WASH",
    FLAG_Teachers == "YES" ~ "Teachers",
    FLAG_Displacement == "YES" ~ "Displacement",
    FLAG_HumanitarianCrises == "YES" ~ "Humanitarian Crises",
    FLAG_Inclusion == "YES" ~ "Inclusion",
    FLAG_Geographic == "YES" ~ "Geographic",
    FLAG_EduFacilities == "YES" ~ "Education Facilities",
    FLAG_OutSchool == "YES" ~ "Out of School",
    FLAG_Learning == "YES" ~ "Learning",
    FLAG_EiERelated == "YES" ~ "EiE Related",
    FLAG_RiskReductionMitigation == "YES" ~ "Risk Reduction Mitigation",
    FLAG_SchoolFeeding == "YES" ~ "School Feeding",
    TRUE ~ "No flag"
  ))

df %<>%
  mutate(
    Flag = if_else(
      rowSums(select(., starts_with("FLAG_")) == "YES", na.rm = TRUE) > 1,
      "Multiple Flags",
      Flag
    )
  )


# flags_countries_sector ----
# Flatten flag columns into long format, keeping key identifying columns
flags_countries_sector <- df %>%
  filter(ToDelete != "Yes") %>%
  mutate(SectorName = ifelse(Dataset == "FTS", "Education in Emergencies", SectorName)) %>%
  pivot_longer(
    cols = starts_with("FLAG_"),
    names_to = "flag_type",
    values_to = "flag_value"
  ) %>%
  filter(flag_value == "YES") %>%
  mutate(
    Flag = case_when(
      flag_type == "FLAG_Protection" ~ "Protection",
      flag_type == "FLAG_MHPSS" ~ "MHPSS",
      flag_type == "FLAG_Gender" ~ "Gender",
      flag_type == "FLAG_EduContinuity" ~ "Education Continuity",
      flag_type == "FLAG_Wash" ~ "WASH",
      flag_type == "FLAG_Teachers" ~ "Teachers",
      flag_type == "FLAG_Displacement" ~ "Displacement",
      flag_type == "FLAG_HumanitarianCrises" ~ "Humanitarian Crises",
      flag_type == "FLAG_Inclusion" ~ "Inclusion",
      flag_type == "FLAG_Geographic" ~ "Geographic",
      flag_type == "FLAG_EduFacilities" ~ "Education Facilities",
      flag_type == "FLAG_OutSchool" ~ "Out of School",
      flag_type == "FLAG_Learning" ~ "Learning",
      flag_type == "FLAG_EiERelated" ~ "EiE Related",
      flag_type == "FLAG_RiskReductionMitigation" ~ "Risk Reduction Mitigation",
      flag_type == "FLAG_SchoolFeeding" ~ "School Feeding",
      TRUE ~ NA_character_
    )
  ) %>%
  select(Flag, SourceOrganization, RecipientCountry, SectorName, AmountUSD)
flags_countries_sector

flags_countries_sector %<>%
  group_by(Flag, SourceOrganization, RecipientCountry, SectorName) %>%
  summarize(Total = sum(AmountUSD, na.rm = TRUE))
flags_countries_sector


# countries_source_sector ----
countries_source_sector <- df %>%
  mutate(SectorName = ifelse(Dataset == "FTS", "Education in Emergencies", SectorName)) %>%
  filter(ToDelete != "Yes") %>%
  group_by(SectorName, SourceOrganization, RecipientCountry) %>%
  summarize(Total = sum(AmountUSD, na.rm = TRUE)) %>%
  select(SectorName, Total, SourceOrganization, RecipientCountry)
countries_source_sector


# triggered_flags ----
# First, compute the correct total before expanding flags
total_amount <- df %>%
  filter(ToDelete != "Yes")
total_amount <- sum(total_amount$AmountUSD, na.rm = TRUE)

# Then process the flags safely
triggered_flags <- df %>%
  filter(ToDelete != "Yes") %>%
  mutate(
    SectorName = ifelse(Dataset == "FTS", "Education in Emergencies", SectorName),
    Flagged = ifelse(Flag != "No flag", "Triggered", "Untriggered")
  ) %>%
  group_by(SectorName, Flagged) %>%
  summarise(TotalAmount = sum(AmountUSD, na.rm = TRUE), .groups = "drop") %>%
  group_by(SectorName, na.rm = TRUE) %>%
  mutate(
    Total = sum(TotalAmount, na.rm = TRUE),
    Percentage = TotalAmount / Total * 100
  ) %>%
  ungroup() %>%
  select(SectorName, Flagged, Total, Percentage)

# Pivot wider to desired format
triggered_flags %<>%
  pivot_wider(
    names_from = Flagged,
    values_from = Percentage,
    values_fill = 0
  ) %>%
  distinct()  # remove any accidental duplicates
triggered_flags

rm(total_amount)

# triggered_flags_sector ----
triggered_flags_sector  <- df %>%
  filter(ToDelete != "Yes") %>%
  mutate(FlagGroup = if_else(Flag == "No flag", "No flag", "Flagged")) %>%
  group_by(SectorName, FlagGroup) %>%
  summarise(Total = sum(AmountUSD, na.rm = TRUE), .groups = "drop_last") %>%
  mutate(SectorTotal = sum(Total, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(Percentage = Total / SectorTotal * 100) %>%
  pivot_wider(names_from = FlagGroup, values_from = c(Total, Percentage), values_fill = 0) %>%
  rename(PerNotTriggered = `Percentage_No flag`,
         PerTriggered = Percentage_Flagged) %>%
  select(SectorName, PerTriggered, PerNotTriggered)
triggered_flags_sector

# CO-OCCURRENCE Matrix ----
# 1. Define FLAG columns
# 1. Define FLAG columns
flag_cols <- grep("^FLAG_", names(df), value = TRUE)

# 2. Filter out rows marked for deletion
df_valid <- df %>% filter(ToDelete != "Yes")

# 3. Initialize co-occurrence list
co_list <- list()

for (i in seq_along(flag_cols)) {
  for (j in seq_along(flag_cols)) {
    flag1 <- flag_cols[i]
    flag2 <- flag_cols[j]
    
    if (i == j) {
      # ✅ Diagonal: total AmountUSD where flag is YES (no division)
      amount_sum <- df_valid %>%
        filter(.data[[flag1]] == "YES") %>%
        summarise(total = sum(AmountUSD, na.rm = TRUE)) %>%
        pull(total)
    } else {
      # ✅ Off-diagonal: total where both flags are YES
      amount_sum <- df_valid %>%
        filter(.data[[flag1]] == "YES", .data[[flag2]] == "YES") %>%
        summarise(total = sum(AmountUSD, na.rm = TRUE)) %>%
        pull(total)
    }
    
    co_list[[length(co_list) + 1]] <- data.frame(
      Flag1 = flag1,
      Flag2 = flag2,
      AmountUSD = amount_sum
    )
  }
}

# 4. (Optional) Rename flags for readability
rename_flags <- function(flag) {
  case_when(
    flag == "FLAG_Protection" ~ "Protection",
    flag == "FLAG_MHPSS" ~ "MHPSS",
    flag == "FLAG_Gender" ~ "Gender",
    flag == "FLAG_EduContinuity" ~ "Education Continuity",
    flag == "FLAG_Wash" ~ "WASH",
    flag == "FLAG_Teachers" ~ "Teachers",
    flag == "FLAG_Displacement" ~ "Displacement",
    flag == "FLAG_HumanitarianCrises" ~ "Humanitarian Crises",
    flag == "FLAG_Inclusion" ~ "Inclusion",
    flag == "FLAG_Geographic" ~ "Geographic",
    flag == "FLAG_EduFacilities" ~ "Education Facilities",
    flag == "FLAG_OutSchool" ~ "Out of School",
    flag == "FLAG_Learning" ~ "Learning",
    flag == "FLAG_EiERelated" ~ "EiE Related",
    flag == "FLAG_RiskReductionMitigation" ~ "Risk Reduction Mitigation",
    flag == "FLAG_SchoolFeeding" ~ "School Feeding",
    TRUE ~ flag
  )
}

# 5. Combine and pivot
co_matrix_df <- bind_rows(co_list) %>%
  mutate(
    Flag1 = rename_flags(Flag1),
    Flag2 = rename_flags(Flag2)
  ) %>%
  group_by(Flag1, Flag2) %>%
  summarise(AmountUSD = sum(AmountUSD, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = Flag2, values_from = AmountUSD, values_fill = 0)

# 6. View or export
print(co_matrix_df)

# 6. Create a working copy for scaling
co_matrix_scaled <- co_matrix_df

# 7. Extract the numeric matrix
mat_only <- co_matrix_scaled[,-1]  # remove row labels (Flag1)

# 8. Min-max scale to [-1, 1]
min_val <- min(mat_only, na.rm = TRUE)
max_val <- max(mat_only, na.rm = TRUE)

mat_scaled <- 2 * ((mat_only - min_val) / (max_val - min_val)) - 1

# 9. Reattach Flag1
co_matrix_scaled[,-1] <- mat_scaled

# 10. Median-based scaling
mat_only <- as.matrix(co_matrix_scaled[,-1])

med_val <- median(mat_only, na.rm = TRUE)

rescale_around_median <- function(x, med, min, max) {
  ifelse(
    is.na(x), NA,
    ifelse(
      x <= med,
      (x - med) / abs(med - min),  # scale to [-1, 0]
      (x - med) / abs(max - med)   # scale to [0, 1]
    )
  )
}

mat_scaled_median <- matrix(
  rescale_around_median(as.vector(mat_only), med_val, min_val, max_val),
  nrow = nrow(mat_only),
  ncol = ncol(mat_only),
  dimnames = dimnames(mat_only)
)

# 11. Final output: scaled diagonal-only matrix
co_matrix_median_scaled <- cbind(Flag1 = co_matrix_scaled[[1]], as.data.frame(mat_scaled_median))

rm(co_df, co_list, flag_logical, flag_cols, df_flags, flag_names, diagonal_values,
   mat_only, min_val, max_val, mat_scaled, mat_scaled_median, med_val, co_matrix_scaled)

# extracted_overlaps ----
extracted_overlaps <- df %>%
  group_by(ToDelete) %>%
  summarize(TotalUSD = sum(AmountUSD, na.rm = TRUE)) %>%
  mutate(Datapoints = ifelse(ToDelete == "Yes", "Deleted", "Final Dataset")) %>%
  select(Datapoints, TotalUSD)
extracted_overlaps

# pyramid ----
pyramid <- df %>%
  filter(ToDelete != "Yes") %>%
  group_by(Dataset, SourceOrganization) %>%
  summarize(TotalUSD = sum(AmountUSD, na.rm = TRUE)) %>%
  pivot_wider(names_from = Dataset, values_from = TotalUSD) %>%
  replace_na(list(FTS = 0, IATI = 0)) %>%
  mutate(TotalUSD = FTS + IATI,
         FTS = FTS / TotalUSD * -1,
         IATI = IATI / TotalUSD)
pyramid

# Prints ----
wb <- createWorkbook()

# Loop through all data frames in the environment
dfs <- mget(ls(envir = .GlobalEnv), envir = .GlobalEnv)

dfs <- dfs[sapply(dfs, is.data.frame)]

for (name in names(dfs)) {
  addWorksheet(wb, sheetName = name)
  writeData(wb, sheet = name, x = dfs[[name]])
}

# prep saving env
# Define the directory path
dir_path <- "data/analysis/"

# Check if directory exists; if not, create it
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}

saveWorkbook(wb, "data/analysis/all_countries_graphs.xlsx", overwrite = TRUE)

