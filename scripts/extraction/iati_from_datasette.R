source("requirements/libraries.R")
rm(list = ls())
# url <- "https://datasette.codeforiati.org/iati.csv?sql=SELECT%0D%0A++*%0D%0AFROM%0D%0A++transaction_breakdown%0D%0AWHERE%0D%0A++sector_code+IN+%28%0D%0A++++%2711110%27%2C%0D%0A++++%2711120%27%2C%0D%0A++++%2711130%27%2C%0D%0A++++%2711182%27%2C%0D%0A++++%2711220%27%2C%0D%0A++++%2711230%27%2C%0D%0A++++%2711231%27%2C%0D%0A++++%2711232%27%2C%0D%0A++++%2711240%27%2C%0D%0A++++%2711250%27%2C%0D%0A++++%2711260%27%2C%0D%0A++++%2711320%27%2C%0D%0A++++%2711321%27%2C%0D%0A++++%2711322%27%2C%0D%0A++++%2711330%27%2C%0D%0A++++%2711420%27%2C%0D%0A++++%2711430%27%2C%0D%0A++++%27111%27%2C%0D%0A++++%27112%27%2C%0D%0A++++%27113%27%2C%0D%0A++++%27114%27%2C%0D%0A++++%2772012%27%2C%0D%0A++++%2743010%27%2C%0D%0A++++%2751010%27%0D%0A++%29%0D%0A++AND+recipientcountry_code+IN+%28%27TD%27%2C+%27ET%27%2C+%27SS%27%2C+%27NG%27%2C+%27CD%27%2C+%27HT%27%29%0D%0A++AND+transactiondate_isodate+%3E+%272020-12-31%27%0D%0A++AND+transactiondate_isodate+%3C+%272024-01-01%27"

# prep saving env
# Define the directory path
dir_path <- "data/raw_extractions/"

# Check if directory exists; if not, create it
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}


# function to emulate url encoding of datasette
custom_url_encode <- function(sql_query) {
  # Replace specific characters for the desired encoding format
  sql_query <- gsub("LIKE '%", "LIKE '%25", sql_query)
  sql_query <- gsub("%'", "%25'", sql_query)      # Replace % with %25 (must be done first to avoid double encoding)
  encoded_query <- gsub(" ", "+", sql_query)       # Replace spaces with +
  encoded_query <- gsub("\n", "%0D%0A", encoded_query)  # Replace newlines with %0D%0A
  encoded_query <- gsub("'", "%27", encoded_query)  # Replace single quotes with %27
  encoded_query <- gsub("\\(", "%28", encoded_query) # Replace ( with %28
  encoded_query <- gsub("\\)", "%29", encoded_query) # Replace ) with %29
  encoded_query <- gsub(",", "%2C", encoded_query)  # Replace commas with %2C
  encoded_query <- gsub("=", "%3D", encoded_query)  # Replace = with %3D
  encoded_query <- gsub(">", "%3E", encoded_query)  # Replace > with %3E
  encoded_query <- gsub("<", "%3C", encoded_query)  # Replace < with %3C
  return(encoded_query)
}

# Define the base URL for the Datasette instance
base_url <- "https://datasette.codeforiati.org/iati.csv?sql="

# Write the SQL query as a string
# Retrieve transactions_breakdown join with activities and trans----
sql_query <- "SELECT 
                    tb.*,
                    tr.*,
                    a.reportingorg_type, 
                    a.reportingorg_narrative,
                    a.humanitarian, 
                    a.title_narrative, 
                    a.description, 
                    a.location,
                    a.defaultfinancetype_code, 
                    a.defaultfinancetype_codename
                      FROM transaction_breakdown tb
                    JOIN trans tr
                    ON tb._link_transaction = tr._link
                    JOIN activity a
                     ON tb._link_activity = a._link
                    WHERE 
                    tb.sector_code IN ('11110', '11120', '11130', '11182', '11220', '11230', '11231', '11232', '11240', '11250', '11260', 
                                       '11320', '11321', '11322', '11330', '11420', '11430', '111', '112', '113', '114', 
                                       '72012', '43010', '43081', '51010')
                   AND tb.recipientcountry_code IN ('TD', 'ET', 'SS', 'NG', 'CD', 'HT')
                    AND tb.transactiondate_isodate > '2020-12-31'
                    AND tb.transactiondate_isodate < '2024-01-01';"

# URL-encode the SQL query
encoded_query <- custom_url_encode(sql_query)

# Construct the full API URL
full_url <- paste0(base_url, encoded_query)

# Print the full URL
print(full_url)

# Send a GET request to the API for CSV data
response <- GET(full_url)

# Check if the request was successful
if (status_code(response) == 200) {
  # Parse the CSV content
  data <- content(response, "raw")
  csv_data_t <- read_csv(file = rawConnection(data))
  
  # Print the first few rows of the data
  print(head(csv_data_t))
  
  # Save the data to a CSV file
  # write.csv(csv_data, paste0("data/raw extractions/", today(),"_datasette_iati.csv"), row.names = FALSE)
  
  print("Transaction breakdown activity data has been extracted")
} else {
  print(paste("Failed to retrieve data. Status code:", status_code(response)))
}

# save raw
write.csv(csv_data_t, paste0("data/raw extractions/datasette_preprocessed/", today(), "_datasette_transaction.csv"), row.names = FALSE)

# VERIFY if it does return the columns name in the same format
# as of 2024-11-01 server not working
# this is transaction not broken down but it contains necessary info for merging
trans <- csv_data_t
trans %<>% 
  rename(LinkActivity = `X_link_activity`,
         LinkTransaction = `X_link_transaction`)

df <- trans


# df %<>%
#   mutate(ExtractionDate = today())

write.csv(df, paste0("data/raw extractions/", today(),"_datasette_iati.csv"), row.names = FALSE)

rm(list = ls())
