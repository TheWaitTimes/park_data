library(dplyr)
library(jsonlite)
library(readr)  # Added for better CSV handling


# EPCOT
epcot_res <- "https://api.themeparks.wiki/v1/entity/47f90d2c-e191-4239-a466-5892ef59a88b/live"
ep_df <- fromJSON(epcot_res, flatten=TRUE)
ep_data <- ep_df$liveData
ep_data$time <- Sys.time()

# Magic Kingdom
mk_res <- "https://api.themeparks.wiki/v1/entity/75ea578a-adc8-4116-a54d-dccb60765ef9/live"
mk_df <- fromJSON(mk_res, flatten=TRUE)
mk_data <- mk_df$liveData
mk_data$time <- Sys.time()

# Hollywood Studios
hs_res <- "https://api.themeparks.wiki/v1/entity/288747d1-8b4f-4a64-867e-ea7c9b27bad8/live"
hs_df <- fromJSON(hs_res, flatten=TRUE)
hs_data <- hs_df$liveData
hs_data$time <- Sys.time()

# Animal Kingdom
ak_res <- "https://api.themeparks.wiki/v1/entity/1c84a229-8862-4648-9c71-378ddd2c7693/live"
ak_df <- fromJSON(ak_res, flatten=TRUE)
ak_data <- ak_df$liveData
ak_data$time <- Sys.time()

dbSafeNames <- function(names) {
  names <- gsub('[^a-z0-9]+', '_', tolower(names))
  names <- make.names(names, unique=TRUE, allow_ = TRUE)
  names <- gsub('.', '_', names, fixed=TRUE)
  names
}

colnames(ep_data) <- dbSafeNames(colnames(ep_data))
colnames(mk_data) <- dbSafeNames(colnames(mk_data))
colnames(hs_data) <- dbSafeNames(colnames(hs_data))
colnames(ak_data) <- dbSafeNames(colnames(ak_data))
# Define the data folder path
data_folder <- "data"

# Ensure the data folder exists
if (!dir.exists(data_folder)) {
  dir.create(data_folder)
}

# Define a function to append data to CSV
append_to_csv <- function(data, file_name) {
  file_path <- file.path(data_folder, file_name)
  if (!file.exists(file_path)) {
    write_csv(data, file_path) # Create a new file if it doesn't exist
  } else {
    write_csv(data, file_path, append = TRUE) # Append to the existing file
  }
}

# Save data to CSVs
append_to_csv(ep_data, "ep_data.csv")
append_to_csv(mk_data, "mk_data.csv")
append_to_csv(hs_data, "hs_data.csv")
append_to_csv(ak_data, "ak_data.csv")
