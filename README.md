# EiEPC Financial Flows

This repository contains an R-based, reproducible workflow to **extract, clean, integrate, and analyze** Education in Emergencies & Protracted Crises (EiEPC) financial flows from **FTS** and **IATI**.

## 🧭 Scope & Objectives

-   Retrieve **FTS** data via API and **IATI** transactions via local database export.
-   Standardize, clean, and **harmonize** sectors, organizations, and countries.
-   Apply **two-layer filtering** (sector/flow type, then donor/org type).
-   Apply **flags** (humanitarian, displacement, out-of-school, DRR, MHPSS, inclusion, gender, EiE, WASH, continuity, school feeding, learning, teachers, crisis geographies, facilities).
-   **De-duplicate** and **merge** FTS + IATI with auditable IDs and logs.

These steps mirror the protocol’s stages and constraints (e.g., FTS API v1 limits, nested/“On Boundary” results; IATI non-uniform sector codes, local SQL performance, name cleaning & correspondence tables).

## 🧱 Repository Structure

```         
.
├── 01 extraction.R
├── 02 processing.R
├── EiEPC Financing Tracking.Rproj
├── README.md
├── config
│   ├── extraction_config.yml
│   ├── filters_config.yml
│   ├── flags_list.yml
├── data
│   ├── analysis
│   ├── clean
│   │   ├── all_countries
│   ├── local db
│   ├── processed
│   ├── raw extractions
│   │   └── fts
│   └── utilities
│       ├── _for checks
│       │   ├── iati_recipients.csv
│       │   ├── new_iati_parent_child.csv
│       │   └── new_names_iati.csv
│       ├── _list_fixes_flag.csv
│       ├── _other
│       │   ├── correspondance_table.xlsx
│       │   ├── list_names_fts_recipients.csv
│       │   ├── list_names_iati.csv
│       │   ├── manual_flag_oldID.xlsx
│       │   ├── names_provider_reporting.csv
│       │   ├── parent_child_orgs_fts.xlsx
│       │   └── parent_child_orgs_iati.xlsx
│       ├── correspondance
│       │   ├── correspondance_new_fts.csv
│       │   ├── correspondance_new_fts_destination.csv
│       │   ├── correspondance_new_iati.csv
│       │   ├── correspondance_new_iati_destination.csv
│       │   ├── correspondance_table.csv
│       │   └── correspondance_table_destination.csv
│       ├── fts_iati_codes.xlsx
│       ├── iso_codes.csv
│       ├── manual_flags.xlsx
│       ├── matched names
│       │   └── matched_names_iati.csv
│       ├── publishers
│       │   ├── list_iati_provider_reporting.csv
│       │   └── new_iati_provider_reporting.csv
│       ├── recipients
│       │   ├── list_names_fts_recipients.csv
│       │   ├── list_names_iati_recipients.csv
│       │   ├── names_fts_new_recipients.csv
│       │   └── names_iati_new_recipients.csv
│       ├── reportingorg type
│       │   ├── list_reporting_type_iati.csv
│       │   └── new_reporting_type_iati.csv
│       ├── revised list
│       │   └── list_fts_revised_names_type.csv
│       └── sourceorg
│           ├── list_names_fts.csv
│           └── new_names_fts.csv
├── requirements
│   ├── flag_iati.R
│   ├── group_flag.R
│   ├── libraries.R
│   └── merge_data_types.R
└── scripts
    ├── analysis
    │   ├── graphs_export_complete.R
    │   └── graphs_export_iteration.R
    ├── extraction
    │   ├── .Rhistory
    │   ├── fts_from_api.R
    │   ├── iati_from_datasette.R
    │   ├── iati_from_localdb.R
    │   └── iati_from_localdb_food security.R
    └── processing
        ├── .Rhistory
        ├── 01_fts_first_processing.R
        ├── 02_iati_first_processing_foodsec.R
        ├── 03_iati_first_processing.R
        ├── 04_fts_iati_first_filter_layer.R
        ├── 05_iati_get_new_publishers_providers.R
        ├── 06_iati_clean_publishers_providers.R
        ├── 07_iati_get_new_reportingorg_type.R
        ├── 08_iati_clean_reportingorg_type.R
        ├── 09_fts_get_new_sourceorg.R
        ├── 10_fts_clean_sourceorg.R
        ├── 11_fts_iati_second_filter_layer.R
        ├── 12_fts_iati_flags.R
        ├── 13_fts_iati_get_new_recipients.R
        ├── 14_iati_clean_recipients.R
        ├── 15_fts_iati_matching_get_new_names.R
        ├── 16_iati_matching_names_to_fts.R
        ├── 17_iati_dubious_flag.R
        ├── 18_fts_iati_merging.R
        └── 19_create_complete_dataset.R
```

## 🛠️ Installation

#### Prep steps

Download the database IatiTables from this link [`https://datasette.tables.iatistandard.org/iati.db`](https://datasette.tables.iatistandard.org/iati.db) and put it in the folder `data/local db/`

### 🔐 Configuration

There is an airtable repository that contains the information needed to complete the config file at this link [`https://airtable.com/appWUula6wmbo480d/paguXtZQIUJdlRpf1`](https://airtable.com/appWUula6wmbo480d/paguXtZQIUJdlRpf1){.uri}. Alternatively, the file to be used is `data/utilities/iso_codes.csv`.

Edit **`config/extraction_config.yml`**:

``` yaml
# Extraction parameters FTS
fts_date = '2025-01-22'
fts_years = c(2021, 2022, 2023, 2024)
# fts_location_ids = c(1, 206, 212, 171, 234) # second iteration
fts_location_ids <- c(44, 52, 96, 71, 163, 211) # first iteration

fts_EduGlobalClusterId = c(3)
fts_MLTSGlobalClusterId = c(26479)
# fts_list_countries = c("Afghanistan", "Somalia", "Sudan", "Occupied Palestinian Territory", "Ukraine") # Second iteration
fts_list_countries <- c("South Sudan", "Chad", "Nigeria", "Ethiopia", "Haiti", "Congo, The Democratic Republic of the") # First iteration


# Extraction parameters IATI
iati_date = '2025-01-15'
iati_start_range = '2020-12-31' # the date range starts one day after
iati_end_range = '2025-01-01' # the date range ends one day before
# iati_countries = c('AF', 'SO', 'SD', 'PS', 'UA') # second iteration
iati_countries <- c('TD', 'ET', 'SS', 'NG', 'CD', 'HT') # first iteration
iati_sectorcodes = c('11110', '11120', '11130', '11182', '11220', '11230', '11231', '11232', '11240', '11250', '11260','11320', 
'11321', '11322', '11330', '11420', '11430', '111', '112', '113', '114','72012', '43010', '43081', '51010')
iati_fs_sectorcode = '52010' 

# ISO3
# countries = c("AFG", "SOM", "SDN", "PSE", "UKR") # second iteration
countries = c("TCD", "ETH", "SSD", "NGA", "COD", "HTI") # first iteration
```

Edit **`config/flags_list.yml`** for keyword lists used in flagging (humanitarian, displacement, MHPSS, etc.).

``` yaml
# Humanitarian Flag ----
humanitarian_flag_search_terms <- c("humanitarian", "humanitaire", "humanitar", "crisis", "crise", "krise", "crises", "emergency", "urgence", "disaster", "desastre", "emergencies", "deplacement", "resilience", "conflict", "conflit", "drought", "secheresse","vulnerable", "risk", "risque", "closure", "cloture", "drop out", "abandon", "resilient", "violence", "attacks","attaque", "idp", "refugees", "refugies", "deplaces", "host", "hote", "marginalised", "accueil", "out-of-school", "out of school", "non scolarises", "returnees", "eie", "esu", "preparedness", "preparation", "school feeding","alimentation scolaire", "psychological", "psychologic", "psychosocial", "catch-up", "rattrapage", "school", "ecole", "protection", "protective", "protecteur", "safe", "sur", "safety", "securite", "insertion", "accelerated", "accelere", "adapted", "adapte", "inclusive", "inclusif", "response", "barriers", "barriere", "mitigation", "continuity", "continuation", "GBV", "violence", "WASH", "assainissement", "adaptation", "DRR", "prevention", "Afar", "Tigray","Amhara", "BG", "Oromia", "Somali", "Benishangul-Gumuz", "Gambella", "Lake Chad", "Wadi Fira", "Biltine", "Dar Tama", "Iriba", "Megri", "Sila", "Djourf Al Ahmar", "Kimiti", "Ouaddaand", "Abdi", "Assoungha", "Ouara", "Nord-Kivu","Sud-Kivu", "Ituri", "Maindombe", "North East", "Bomo", "Borno", "Yobe", "Adamawa", "Gombe"
)

# Language flags ----
## Humanitarian ----
humanitarian <- c("humanitarian", "humanitaire", "humanitar", "crisis", "crise", "krise","crises", "emergency", "urgence", "disaster", "desastre", "emergencies", "drought", "secheresse", "violence", "attacks", "attaque", "flood", "earthquake", "cyclone", "response"
)

## Displacement ----
displacement <- c("idp", "refugees", "refugies", "deplaces", "host", "hote", "hotes", "accueil", "returnees", "deplacement", "displaced", "displacement", "UNHCR", "HCR", "IOM", "OIM"
)

## Out-of-school ----
out_school <- c("out-of-school", "out of school", "non scolarises", "descolarise", "descolarises")

## Risk-reduction-mitigation ----
risk_red_mitigation <- c( "climate change", "changement climatique", "climate adaptation","adaptation climatique", "climate mitigation", "greening education", "climate","climat", "durabilité", "sustainability", "risk", "risque", "preparedness", "preparation", "DRR", "mitigation", "prevention", "adaptation", "resilience", "CSSF", "contingence")

## Protection ----
protection <- c("protection", "protective", "protecteur", "safe", "safety", "securite", "surete")

## MHPSS ----
mhpss <- c("psychological", "psychologic", "psychosocial", "mental health", "counselor","counselors", "counseling")

## Inclusion ----
inclusion <- c("inclusif", "inclusive", "adapted", "adapte", "disability", "inclusion", "handicap", "disabled", "barriers", "barriere")

## Gender ----
gender <- c("gender", "fille", "filles", "girls", "GBV", "equity", "femme", "women"")

## EiE ----
eie <- c("eie", "esu")

## WASH ----
wash <- c("WASH", "assainissement", "latrine", "latrines", "hygiene")

## Education continuity ----
edu_continuity <- c("drop out", "abandon", "catch-up", "rattrapage", "reinsertion",  "continuation", "insertion", "accelerated", "accelere", "alternative", "radio")

## School feeding ----
school_feeding <- c( "school feeding", "alimentation scolaire", "cantine", "malnutrition", "nutrition", "WFP", "PAM")

## Learning ----
learning <- c("learning", "social emotional learning", "apprentissage", "qualite", "quality", "outcomes")

## Geographic ----
geographic <- c("Afar", "Tigray", "Amhara", "BG", "Oromia", "Somali", "Benishangul-Gumuz", "Gambella","Lake Chad", "Wadi Fira", "Biltine", "Dar Tama", "Iriba", "Megri", "Sila", "Djourf Al Ahmar", "Lac","Kimiti", "Ouaddaand", "Abdi", "Assoungha", "Ouara","Nord-Kivu", "Sud-Kivu", "Ituri", "Maindombe","North East", "Bomo", "Borno", "Yobe", "Adamawa", "Gombe")

## Teachers ----
teachers <- c("teachers", "teacher", "educateur", "educateurs","enseignant", "enseignants", "lehrkrafte", "lehrer", "lehrerin")

## Education facilities ----
edu_facilities <- c("construction", "building", "facilities", "salle de classe", "salles de classe", "classroom", "classrooms", "schule")
```

### ▶️ Outputs

Key outputs are written to `data/clean/` and `data/analysis/` include:

-   single iteration data in folders named after the ISO codes of the iteration

-   combined dataset `complete_dataset.csv`

-   separated `fts.csv` and `iati.csv`

## 🔄 Workflow

Below is the pipeline distilled into stages. Items marked 🟦 are automated; 🟪 require manual review (as per protocol).

``` mermaid
flowchart TD
  %% ==== CLASS DEFINITIONS ====
  classDef auto   fill:#e6f2ff,stroke:#4a90e2,stroke-width:1px,color:#0b3660;
  classDef manual fill:#efe1ff,stroke:#7b61ff,stroke-width:1px,color:#2e1961;

  %% ==== FTS BRANCH ====
  A["Understand priorities & params.yml"]:::auto --> 
  B["FTS: retrieve country & sector codes"]:::auto -->
  C["FTS: API extract (batched) + early de-nesting"]:::auto -->
  D["FTS: standardize columns & sector cleaning"]:::auto

  %% ==== IATI BRANCH ====
  A --> E["IATI: download/ingest local DB (IatiTables flattened)"]:::auto -->
  F["IATI: two extractions - Education & Food Security"]:::auto -->
  G["IATI: process & standardize; create unique ID"]:::auto

  %% ==== FIRST FILTER ====
  G --> H["First filter: sectors & (IATI) disbursements only"]:::auto
  D --> H

  %% ==== NAME PROCESSING ====
  H --> I["Names processing: source orgs (publisher ↔ transaction_provider)"]:::manual -->
  J["Names processing: reporting org types fixed"]:::manual
  D --> K["FTS: verify parent/child orgs"]:::manual

  %% ==== SECOND FILTER ====
  J --> L["Second filter: donor/org types (bilateral, multilateral)"]:::auto
  K --> L

  %% ==== TEXT FLAGS & CLEANING ====
  L --> M["Text flags on titles/descriptions (humanitarian, etc.)"]:::auto -->
  N["Clean recipient names (IATI only)"]:::manual

  %% ==== MATCHING & FINAL MERGE ====
  N --> O["Names matching: align IATI → FTS naming standard"]:::manual -->
  P["Flag dubious transactions (donor=recipient same cntry/yr)"]:::manual -->
  Q["Merge FTS + IATI; deduplicate & log decisions"]:::auto -->
  R["Export final datasets + logs"]:::auto

  %% ==== LEGEND ====
  subgraph Legend
    L1["automated"]:::auto
    L2["manual review"]:::manual
  end
```

### 🧩 Key stages

The code is structured to pause when manual verification and updates are needed. When the verification is done and the files are updated, just click `ok` in the popup to prosecute with executing the scripts.

-   **FTS extraction (API v1, batched)**: Respect call limits; pre-clean nested structures so they can be saved efficiently. Handle **“On Boundary”** caveats where flows with multiple values are included in search results but excluded from totals for any single parameter. FTS extracts based on the parameters given in the config file. Meaning that if you need latest data form other countries it needs to be re-extracted.\

-   **IATI extraction (local)**: Use a local SQLlite db copy of **IatiTables** (flattened). Join `transaction_breakdown`, `trans`, `activity` with proper keys. Run **two passes** (Education; Food Security) and then text-filter for education-relevant records from Food Security. Expect heavy joins for multi-year, multi-country pulls. IATI extracts based on the sector and year parameters given. As it is very time consuming to extract IATI data, all the countries are included. To iterate over a new country, it is not necessary to extract again.

-   **Identifiers**: To check duplicated transactions a new identifier as created, as the IATI transaction identifier varies over versions of the database

    -   IATI ID: `ActivityID_ReportingOrgID_RecipientCountry_SectorCode_RecipientOrgName_TransactionDate_Amount`\
    -   FTS ID: `SourceOrgID_ISO3_Sector_DestinationOrgID_Date_AmountUSD`\

-   **Filtering strategy**: First by **sector/flow type** (retain IATI disbursements only), then by **donor/org type** after name normalization later in the flow. It is structured this way as the main difficulty of IATI is the name inconsistencies. This should be manually verified.\

-   **Name processing**: Maintain and version **correspondence tables** for (a) publisher ↔ transaction_provider, (b) IATI ↔ FTS donor names, (c) recipients. Manual checks are expected and incremental (country-by-country). You can use the table here to look for correspondence names and update the tables accordingly [`https://airtable.com/appXKfSrXdPPrtInZ/pagMeJ143y7rJufo1`](https://airtable.com/appXKfSrXdPPrtInZ/pagMeJ143y7rJufo1){.uri}. Alternatively, the same list is provided here `data/utilities/fts_iati_orgs.csv`.

-   **Flags**: Keyword-based flags on titles/descriptions for humanitarian/EiE dimensions. Keep the keyword lists in `config/flags.yml` and version them.\

-   **Duplicates**: Maintain the log of duplicates in `data/utilities/manual_flags.xlsx` providing per country sheet (named after ISO2 code) the necessary information.

-   The latest stage involves the **merging of the two datasets** and the output is to be used with the analysis flow.

-   The **analysis flow** provides tables ready to be manually imported in Flourish.\

## ⚠️ Known Limitations & Risks

-   **FTS v1** limitations and possible framework changes require maintenance.
-   **IATI** sector codes may be non‑DAC; those records are currently excluded unless you add custom mappings.
-   **Manual steps** are necessary for high-quality name harmonization and duplicate decisions; keep correspondence tables under version control and treat them as **data assets**.
-   **Performance**: Large multi-country, multi-year extracts are computationally heavy; expect long runtimes on first ingestion.
-   **Currency**: IATI `transaction_breakdown` uses fluctuating USD rates; comparisons across different extraction dates may shift—document extraction dates in metadata.
-   **Dates**: When querying SQL, use `"YYYY-MM-DD"` format strictly.

## 📚 Citation & Context

This repository operationalizes ECW internal **“Data Extraction, Processing and Analysis Protocol”** for EiEPC finance across **FTS** and **IATI**.
