source("setup.R")

# --- Data processing ---
run_stage("scripts/processing/01_fts_first_processing.R")
run_stage("scripts/processing/02_iati_first_processing_foodsec.R")
run_stage("scripts/processing/03_iati_first_processing.R")

# --- First layer filtering ---
run_stage("scripts/processing/04_fts_iati_first_filter_layer.R")

# --- IATI publishers/providers ---
run_stage("scripts/processing/05_iati_get_new_publishers_providers.R")
CHECK("CHECK - data/utilities/publishers/ - check new, update list")
run_stage("scripts/processing/06_iati_clean_publishers_providers.R")

# --- Reporting org type ---
run_stage("scripts/processing/07_iati_get_new_reportingorg_type.R")
CHECK("CHECK - data/utilities/reportingorg type/ - check new, update list")
run_stage("scripts/processing/08_iati_clean_reportingorg_type.R")

# --- Source organizations ---
run_stage("scripts/processing/09_fts_get_new_sourceorg.R")
CHECK("CHECK - data/utilities/sourceorg/ - check new, update list")
run_stage("scripts/processing/10_fts_clean_sourceorg.R")

# --- Continue the pipeline ---
run_stage("scripts/processing/11_fts_iati_second_filter_layer.R")
run_stage("scripts/processing/12_fts_iati_flags.R")

run_stage("scripts/processing/13_fts_iati_get_new_recipients.R")
CHECK("CHECK - data/utilities/recipients/ - check new fts and iati, update lists")
run_stage("scripts/processing/14_iati_clean_recipients.R")

run_stage("scripts/processing/15_fts_iati_matching_get_new_names.R")
CHECK("CHECK - data/utilities/correspondance/ - check and update correspondance tables")
run_stage("scripts/processing/16_iati_matching_names_to_fts.R")

run_stage("scripts/processing/17_iati_dubious_flag.R")
run_stage("scripts/processing/18_fts_iati_merging_alternative.R")
run_stage("scripts/processing/19_create_complete_dataset.R")

CHECK("End of processing. Dataset ready for analysis. Remember to update revised utilities lists if needed.")
