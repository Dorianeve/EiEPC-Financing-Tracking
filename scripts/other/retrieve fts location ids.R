source("requirements/libraries.R")
#source("extraction_config.yml")
rm(list = ls())

# Define the API URL
url <- "https://api.hpc.tools/v2/public/location"

# Send GET request to the API
response <- GET(url)

# Check if the request was successful
if (status_code(response) == 200) {
  # Parse the JSON content
  data <- content(response, as = "text", encoding = "UTF-8")
  # Convert JSON to a list
  data_list <- fromJSON(data, flatten = TRUE)
  # Convert the list to a dataframe
  location_list <- as.data.frame(data_list)
  # View the first few rows of the dataframe
  head(location_list)
} else {
  # Print an error message if the request failed
  print(paste("Error:", status_code(response)))
}

write.csv(location_list, "")
