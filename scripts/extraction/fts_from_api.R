source("requirements/libraries.R")
source("config/extraction_config.yml")

# prep saving env
# Concatenate into one path
dir_path <- file.path("data/raw extractions/fts", paste(countries, collapse = "_"))

# Check if directory exists; if not, create it
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}

# API FTS Education ----

# Define the base API URL (v1)
url <- "https://api.hpc.tools/v1/public/fts/flow"

# Define the list of years and location IDs
years <- fts_years
location_ids <- fts_location_ids

# Create an empty dataframe to store all the data
all_flows_df <- data.frame()
expected_cols <- NULL  ### MODIFIED: New variable to store expected column names
# Initialize a counter for data points
data_point_counter <- 0
# Loop over each year
for (year in years) {
  # Loop over each location ID
  for (locationid in location_ids) {
    # Define the query parameters for the current year and location ID
    query_params <- list(
      locationid = locationid,
      year = year,
      boundary = "incoming",
      'filterBy[0]' = "destinationGlobalClusterId:3",
      format = "json",
      limit = 1000
    )
    # Send the API request
    response <- GET(url, query = query_params)
    # Check if the request was successful
    if (status_code(response) == 200) {
      # Parse the JSON response with flattening
      data <- fromJSON(content(response, "text"), flatten = TRUE)
      # Extract the flows data
      flows <- data$data$flows
      # If flows are present and non-empty, store them in the dataframe
      if (!is.null(flows) && length(flows) > 0) {
        # Add year and location ID to the flows records
        flows_df <- data.frame(flows)
        flows_df$year <- year
        flows_df$locationid <- locationid
        
        ### MODIFIED: Ensure column consistency
        if (is.null(expected_cols)) {
          expected_cols <- colnames(flows_df)  # First time: save the structure
        } else {
          missing <- setdiff(expected_cols, colnames(flows_df))
          extra <- setdiff(colnames(flows_df), expected_cols)
          
          for (col in missing) {
            flows_df[[col]] <- NA  # Fill missing expected columns with NA
          }
          flows_df <- flows_df[, expected_cols, drop = FALSE]  # Drop extra columns
        } ### MODIFICATION ENDS HERE
        
        # Combine the new flows with the overall dataframe
        all_flows_df <- rbind(all_flows_df, flows_df)
        # Update the data point counter
        data_point_counter <- data_point_counter + nrow(flows_df)
      }
      # Print progress with data point counter
      cat("Retrieved data for year", year, "and location ID", locationid, "\n")
      cat("Total data points received so far:", data_point_counter, "\n")
    } else {
      # Print error message if the request fails
      cat("Failed to retrieve data for year", year, "and location ID", locationid, 
          "- Status code:", status_code(response), "\n")
    }
    # Pause for a short time between requests to avoid overloading the API
    Sys.sleep(1)
  }
}

# Save the resulting dataframe for manipulation
flows <- all_flows_df

# Flattening nested tables ----
flows <- flows %>%
  mutate(
    SourceOrganization = map(sourceObjects, ~ pluck(filter(.x, type == "Organization"), "name")),
    SourceOrganizationID = map(sourceObjects, ~ pluck(filter(.x, type == "Organization"), "id")),
    DonorType = map(sourceObjects, ~ pluck(filter(.x, type == "Organization"), "organizationTypes")),
    DestinationOrganization = map(destinationObjects, ~ pluck(filter(.x, type == "Organization"), "name")),
    DestinationOrganizationID = map(destinationObjects, ~ pluck(filter(.x, type == "Organization"), "id")),
    Cluster = map(destinationObjects, ~ pluck(filter(.x, type == "Cluster"), "name")),
    ClusterBehavior = map(destinationObjects, ~ pluck(filter(.x, type == "Cluster"), "behavior")),
    GlobalCluster = map(destinationObjects, ~ pluck(filter(.x, type == "GlobalCluster"), "name")),
    GlobalClusterBehavior = map(destinationObjects, ~ pluck(filter(.x, type == "GlobalCluster"), "behavior")),
    RecipientCountry = map(destinationObjects, ~ pluck(filter(.x, type == "Location"), "name")),
    ActivityName = map(destinationObjects, ~ pluck(filter(.x, type == "Project"), "name")),
    DestinationPlanID = map(destinationObjects, ~ pluck(filter(.x, type == "Plan"), "id")),
    DestinationPlan = map(destinationObjects, ~ pluck(filter(.x, type == "Plan"), "name")),
    ReportingOrg = map(reportDetails, ~ pluck(.x, "organization")))

# Substitute NAs
flows <- flows %>% 
  mutate(across(everything(), ~ ifelse(. == "character(0)", NA, .)))

# Unlist lists ---- 
flows <- flows %>% 
  mutate(DonorType = sapply(DonorType, function(x) if (length(x) == 0) NA else x)) %>% 
  mutate(DonorType = unlist(DonorType))

flows <- flows %>% 
  mutate(RecipientCountry = sapply(RecipientCountry, paste, collapse = ", "))

flows <- flows %>%
  mutate(
    SourceOrganization = unlist(SourceOrganization),
    childFlowIds = map_chr(childFlowIds, ~ paste(.x, collapse = ",")),  # Combine elements as a comma-separated string
    Cluster = map_chr(Cluster, ~ paste(.x, collapse = ",")),  # Combine Cluster elements into a string
    ClusterBehavior = map_chr(ClusterBehavior, ~ paste(.x, collapse = ",")),
    GlobalCluster = map_chr(GlobalCluster, ~ paste(.x, collapse = ",")),
    GlobalClusterBehavior = map_chr(GlobalClusterBehavior, ~ paste(.x, collapse = ",")),
    ReportingOrg = map_chr(ReportingOrg, ~ paste(.x, collapse = ",")),
    ActivityName = map_chr(ActivityName, ~ paste(.x, collapse = ",")),
    DestinationPlan = map_chr(DestinationPlan, ~ paste(.x, collapse = ",")),
    SourceOrganizationID = map_chr(SourceOrganizationID, ~ paste(.x, collapse = ",")),
    DonorType = map_chr(DonorType, ~ paste(.x, collapse = ",")),
    DestinationOrganization = map_chr(DestinationOrganization, ~ paste(.x, collapse = ",")),
    DestinationOrganizationID = map_chr(DestinationOrganizationID, ~ paste(.x, collapse = ",")),
    grandBargainEarmarkingType = map_chr(grandBargainEarmarkingType, ~ paste(.x, collapse = ",")),
    keywords = map_chr(keywords, ~ paste(.x, collapse = ",")),
    RecipientCountry = map_chr(RecipientCountry, ~ paste(.x, collapse = ",")))

# Manipulate fields (Multisector vs Education) ---
flows <- flows %>% 
  mutate(GlobalCluster = ifelse(
    str_to_lower(stri_trans_general(GlobalCluster, "Latin-ASCII")) == "education", 
    "Education", 
    "Multisector (with Education)"
  ))

flows <- flows %>%
  mutate(
    DonorType = as.character(DonorType)  # Remove the names attribute and convert to plain character vector
  )

# Make sure to handle precisely NA
flows <- flows %>% 
  mutate(across(everything(), ~ ifelse(. == "character(0)", NA, .)))

# Handling of single / share behavior in country, cluster, global cluster
list_countries <- c("South Sudan", "Chad", "Nigeria", "Ethiopia", "Haiti", "Congo, The Democratic Republic of the")

flows <- flows %>%
  mutate(RecipientCountryBehavior = ifelse(RecipientCountry %in% list_countries, "Single",
                                           "Shared"))

flows <- flows %>%
  mutate(ClusterBehavior = case_when(
    ClusterBehavior == "single" ~ "Single",
    grepl("shared", ClusterBehavior, ignore.case = TRUE) ~ "Shared",
    TRUE ~ NA))

flows <- flows %>%
  mutate(GlobalClusterBehavior = case_when(
    GlobalClusterBehavior == "single" ~ "Single",
    grepl("shared", GlobalClusterBehavior, ignore.case = TRUE) ~ "Shared",
    TRUE ~ NA))

flows <- flows %>% 
  mutate(across(everything(), ~ ifelse(. == "NA", NA, .)))

# Process LocationID ----
location_list <- read.csv("data/utilities/iso_codes.csv", encoding = "UTF-8")

location_list <- location_list %>%
  rename(locationid = ID_fts,
         DestinationCountry = Name_fts) %>%
  select(locationid, ISO3, DestinationCountry)
  
flows <- flows %>%
  left_join(location_list, by = "locationid")

# GHO ----
flows <- flows %>%
  mutate(GHO = case_when(
    is.na(DestinationPlan) ~ "Outside",
    TRUE ~ "Inside"
  ))

# Capitalize the first letter of each word in the column names
colnames(flows) <- sapply(colnames(flows), function(x) {
  paste(toupper(substring(x, 1, 1)), substring(x, 2), sep = "")
})

# View the updated column names
colnames(flows)

# Rename and select fields 
flows <- flows %>%
  rename(ID = Id,
         DestinationCountryID = Locationid) %>%
  select(ID, ParentFlowId, ChildFlowIds,
         Date, ContributionType, OriginalAmount, OriginalCurrency,
         ExchangeRate, AmountUSD, FlowType, Method,
         SourceOrganization, SourceOrganizationID, DonorType, 
         DestinationOrganization, DestinationOrganizationID, DestinationPlan, GHO,
         Cluster, ClusterBehavior, GlobalCluster, GlobalClusterBehavior, 
         RecipientCountry, RecipientCountryBehavior,
         DestinationCountryID, DestinationCountry, ISO3, Year, ActivityName, 
         Description, ReportingOrg, OnBoundary)

# Date conversion
flows$Date <- as.POSIXct(flows$Date, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
flows$Date <- as.Date(flows$Date)

# No scientific notation
options(scipen = 999)

edu <- flows 

rm(flows)
# API FTS Multisector ----

# Define the base API URL (v1)
url <- "https://api.hpc.tools/v1/public/fts/flow"

# Define the list of years and location IDs
years <- fts_years
location_ids <- fts_location_ids

# Create an empty dataframe to store all the data
all_flows_df <- data.frame()
expected_cols <- NULL  ### MODIFIED: New variable to store expected column names

# Initialize a counter for data points
data_point_counter <- 0
# Loop over each year
for (year in years) {
  # Loop over each location ID
  for (locationid in location_ids) {
    # Define the query parameters for the current year and location ID
    query_params <- list(
      locationid = locationid,
      year = year,
      boundary = "incoming",
      'filterBy[0]' = "destinationGlobalClusterId:26479",
      format = "json",
      limit = 1000
    )
    # Send the API request
    response <- GET(url, query = query_params)
    # Check if the request was successful
    if (status_code(response) == 200) {
      # Parse the JSON response with flattening
      data <- fromJSON(content(response, "text"), flatten = TRUE)
      # Extract the flows data
      flows <- data$data$flows
      # If flows are present and non-empty, store them in the dataframe
      if (!is.null(flows) && length(flows) > 0) {
        # Add year and location ID to the flows records
        flows_df <- data.frame(flows)
        flows_df$year <- year
        flows_df$locationid <- locationid
        ### MODIFIED: Ensure column consistency
        if (is.null(expected_cols)) {
          expected_cols <- colnames(flows_df)  # First time: save the structure
        } else {
          missing <- setdiff(expected_cols, colnames(flows_df))
          extra <- setdiff(colnames(flows_df), expected_cols)
          
          for (col in missing) {
            flows_df[[col]] <- NA  # Fill missing expected columns with NA
          }
          flows_df <- flows_df[, expected_cols, drop = FALSE]  # Drop extra columns
        } ### MODIFICATION ENDS HERE
        
        # Combine the new flows with the overall dataframe
        all_flows_df <- rbind(all_flows_df, flows_df)
        # Update the data point counter
        data_point_counter <- data_point_counter + nrow(flows_df)
      }
      # Print progress with data point counter
      cat("Retrieved data for year", year, "and location ID", locationid, "\n")
      cat("Total data points received so far:", data_point_counter, "\n")
    } else {
      # Print error message if the request fails
      cat("Failed to retrieve data for year", year, "and location ID", locationid, 
          "- Status code:", status_code(response), "\n")
    }
    # Pause for a short time between requests to avoid overloading the API
    Sys.sleep(1)
  }
}

# Save the resulting dataframe for manipulation
flows <- all_flows_df

# Flattening nested tables ----
flows <- flows %>%
  mutate(
    SourceOrganization = map(sourceObjects, ~ pluck(filter(.x, type == "Organization"), "name")),
    SourceOrganizationID = map(sourceObjects, ~ pluck(filter(.x, type == "Organization"), "id")),
    DonorType = map(sourceObjects, ~ pluck(filter(.x, type == "Organization"), "organizationTypes")),
    DestinationOrganization = map(destinationObjects, ~ pluck(filter(.x, type == "Organization"), "name")),
    DestinationOrganizationID = map(destinationObjects, ~ pluck(filter(.x, type == "Organization"), "id")),
    Cluster = map(destinationObjects, ~ pluck(filter(.x, type == "Cluster"), "name")),
    ClusterBehavior = map(destinationObjects, ~ pluck(filter(.x, type == "Cluster"), "behavior")),
    GlobalCluster = map(destinationObjects, ~ pluck(filter(.x, type == "GlobalCluster"), "name")),
    GlobalClusterBehavior = map(destinationObjects, ~ pluck(filter(.x, type == "GlobalCluster"), "behavior")),
    RecipientCountry = map(destinationObjects, ~ pluck(filter(.x, type == "Location"), "name")),
    ActivityName = map(destinationObjects, ~ pluck(filter(.x, type == "Project"), "name")),
    DestinationPlanID = map(destinationObjects, ~ pluck(filter(.x, type == "Plan"), "id")),
    DestinationPlan = map(destinationObjects, ~ pluck(filter(.x, type == "Plan"), "name")),
    ReportingOrg = map(reportDetails, ~ pluck(.x, "organization")))

# Substitute NAs
flows <- flows %>% 
  mutate(across(everything(), ~ ifelse(. == "character(0)", NA, .)))

# Unlist lists ---- 
flows <- flows %>% 
  mutate(DonorType = sapply(DonorType, function(x) if (length(x) == 0) NA else x)) %>% 
  mutate(DonorType = unlist(DonorType))

flows <- flows %>% 
  mutate(RecipientCountry = sapply(RecipientCountry, paste, collapse = ", "))

flows <- flows %>%
  mutate(
    SourceOrganization = unlist(SourceOrganization),
    childFlowIds = map_chr(childFlowIds, ~ paste(.x, collapse = ",")),  # Combine elements as a comma-separated string
    Cluster = map_chr(Cluster, ~ paste(.x, collapse = ",")),  # Combine Cluster elements into a string
    ClusterBehavior = map_chr(ClusterBehavior, ~ paste(.x, collapse = ",")),
    GlobalCluster = map_chr(GlobalCluster, ~ paste(.x, collapse = ",")),
    GlobalClusterBehavior = map_chr(GlobalClusterBehavior, ~ paste(.x, collapse = ",")),
    ReportingOrg = map_chr(ReportingOrg, ~ paste(.x, collapse = ",")),
    ActivityName = map_chr(ActivityName, ~ paste(.x, collapse = ",")),
    DestinationPlan = map_chr(DestinationPlan, ~ paste(.x, collapse = ",")),
    SourceOrganizationID = map_chr(SourceOrganizationID, ~ paste(.x, collapse = ",")),
    DonorType = map_chr(DonorType, ~ paste(.x, collapse = ",")),
    DestinationOrganization = map_chr(DestinationOrganization, ~ paste(.x, collapse = ",")),
    DestinationOrganizationID = map_chr(DestinationOrganizationID, ~ paste(.x, collapse = ",")),
    grandBargainEarmarkingType = map_chr(grandBargainEarmarkingType, ~ paste(.x, collapse = ",")),
    keywords = map_chr(keywords, ~ paste(.x, collapse = ",")),
    RecipientCountry = map_chr(RecipientCountry, ~ paste(.x, collapse = ",")))

# Manipulate fields (Multisector vs Education) ---
flows <- flows %>% 
  mutate(GlobalCluster = str_to_lower(stri_trans_general(GlobalCluster, "Latin-ASCII")))

flows <- flows %>% 
  mutate(GlobalCluster = ifelse(
    grepl("education", GlobalCluster, ignore.case = TRUE),"Multisector (with Education)",
    "Multisector"
  ))




flows <- flows %>%
  mutate(
    DonorType = as.character(DonorType)  # Remove the names attribute and convert to plain character vector
  )

# Make sure to handle precisely NA
flows <- flows %>% 
  mutate(across(everything(), ~ ifelse(. == "character(0)", NA, .)))

# flows <- flows %>% 
#   mutate(DonorType = sapply(DonorType, function(x) if (length(x) == 0) NA else x)) %>% 
#   mutate(DonorType = unlist(DonorType))



# flows <- flows %>% 
#   mutate(RecipientCountry = sapply(RecipientCountry, paste, collapse = ", "))


list_countries <- c("South Sudan", "Chad", "Nigeria", "Ethiopia", "Haiti", "Congo, The Democratic Republic of the")

flows <- flows %>%
  mutate(RecipientCountryBehavior = ifelse(RecipientCountry %in% list_countries, "Single",
                                           "Shared"))

flows <- flows %>%
  mutate(ClusterBehavior = case_when(
    ClusterBehavior == "single" ~ "Single",
    grepl("shared", ClusterBehavior, ignore.case = TRUE) ~ "Shared",
    TRUE ~ NA))

flows <- flows %>%
  mutate(GlobalClusterBehavior = case_when(
    GlobalClusterBehavior == "single" ~ "Single",
    grepl("shared", GlobalClusterBehavior, ignore.case = TRUE) ~ "Shared",
    TRUE ~ NA))

flows <- flows %>% 
  mutate(across(everything(), ~ ifelse(. == "NA", NA, .)))

# Process LocationID
# Process LocationID ----
location_list <- read.csv("data/utilities/iso_codes.csv", encoding = "UTF-8")

location_list <- location_list %>%
  rename(locationid = ID_fts,
         DestinationCountry = Name_fts) %>%
  select(locationid, ISO3, DestinationCountry)

flows <- flows %>%
  left_join(location_list, by = "locationid")

flows <- flows %>%
  mutate(GHO = case_when(
    is.na(DestinationPlan) ~ "Outside",
    TRUE ~ "Inside"
  ))

# Capitalize the first letter of each word in the column names
colnames(flows) <- sapply(colnames(flows), function(x) {
  paste(toupper(substring(x, 1, 1)), substring(x, 2), sep = "")
})

# View the updated column names
colnames(flows)

flows <- flows %>%
  rename(ID = Id,
         DestinationCountryID = Locationid) %>%
  select(ID, ParentFlowId, ChildFlowIds,
         Date, ContributionType, OriginalAmount, OriginalCurrency,
         ExchangeRate, AmountUSD, FlowType, Method,
         SourceOrganization, SourceOrganizationID, DonorType, 
         DestinationOrganization, DestinationOrganizationID, DestinationPlan, GHO,
         Cluster, ClusterBehavior, GlobalCluster, GlobalClusterBehavior, 
         RecipientCountry, RecipientCountryBehavior,
         DestinationCountryID, DestinationCountry, ISO3, Year, ActivityName, 
         Description, ReportingOrg, OnBoundary)

# Date conversion
flows$Date <- as.POSIXct(flows$Date, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
flows$Date <- as.Date(flows$Date)

# No scientific notation
options(scipen = 999)

multi <- flows

flows <- rbind(edu, multi)

# flows %<>%
#   mutate(ExtractionDate = today())

write.csv(flows, paste0(dir_path, "/",today(), "_fts_api.csv"), row.names = FALSE)

rm(list = ls())