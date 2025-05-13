library(dplyr)
library(jsonlite)
library(readr)  # Added for better CSV handling

# Safe column names function
dbSafeNames <- function(names) {
  names <- gsub('[^a-z0-9]+', '_', tolower(names))
  names <- make.names(names, unique=TRUE, allow_=TRUE)
  names <- gsub('.', '_', names, fixed=TRUE)
  names <- gsub('[^a-fA-F0-9]', '_', names)  # Ensure only valid hexadecimal characters
  names
}

# Fetch and process data
fetch_and_process_data <- function(url, cols) {
  df <- fromJSON(url, flatten=TRUE)$liveData
  df$time <- Sys.time()
  df <- df[cols]
  df
}

# Data URLs and columns to keep
urls <- list(
  epcot = list(url = "https://api.themeparks.wiki/v1/entity/47f90d2c-e191-4239-a466-5892ef59a88b/live", cols = c(2:3, 6:7, 12:28)),
  magic_kingdom = list(url = "https://api.themeparks.wiki/v1/entity/75ea578a-adc8-4116-a54d-dccb60765ef9/live", cols = c(2:3, 6, 12:26)),
  hollywood_studios = list(url = "https://api.themeparks.wiki/v1/entity/288747d1-8b4f-4a64-867e-ea7c9b27bad8/live", cols = c(2:3, 6, 12:23)),
  animal_kingdom = list(url = "https://api.themeparks.wiki/v1/entity/1c84a229-8862-4648-9c71-378ddd2c7693/live", cols = c(2:3, 6, 7, 12:22))
)

# Ensure the 'data' directory exists
if (!dir.exists("data")) {
  dir.create("data")
}

# Process each park's data and write to CSV
for (park in names(urls)) {
  # Fetch and process data for the current park
  data <- fetch_and_process_data(urls[[park]]$url, urls[[park]]$cols)
  
  # Sanitize column names
  colnames(data) <- dbSafeNames(colnames(data))
  
  # Define the file path for the CSV inside the 'data' folder
  file_path <- paste0("data/", park, "_data.csv")
  
  # Check if the file exists
  if (file.exists(file_path)) {
    # Append new data to the existing CSV
    write_csv(data, file_path, append = TRUE)
  } else {
    # Write new data to a new CSV file (include column names)
    write_csv(data, file_path)
  }
}
