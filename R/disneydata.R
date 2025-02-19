library(DBI)
library(RPostgres)
library(dplyr)
library(jsonlite)

db_host <- Sys.getenv("DB_HOST")
db_port <- Sys.getenv("DB_PORT")
db_user <- Sys.getenv("DB_USER")
db_password <- Sys.getenv("DB_PASSWORD")
db_name <- Sys.getenv("DB_NAME")

# Function to connect to the database with retry logic
connect_db <- function(retries = 5) {
  for (i in 1:retries) {
    con <- tryCatch({
      dbConnect(RPostgres::Postgres(),
                host = db_host,
                port = db_port,
                user = db_user,
                password = db_password,
                dbname = db_name)
    }, error = function(e) {
      message(paste("Connection attempt", i, "failed:", e$message))
      Sys.sleep(5) # Wait 5 seconds before retrying
      NULL
    })
    if (!is.null(con)) return(con)
  }
  stop("Failed to connect to the database after", retries, "attempts")
}

# Connect to the PostgreSQL database
con <- connect_db()

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

# Safe column names function
dbSafeNames <- function(names) {
  names <- gsub('[^a-z0-9]+', '_', tolower(names))
  names <- make.names(names, unique=TRUE, allow_=TRUE)
  names <- gsub('.', '_', names, fixed=TRUE)
  names <- gsub('[^a-fA-F0-9]', '_', names)  # Ensure only valid hexadecimal characters
  names
}

# Process each park's data and write to the database
for (park in names(urls)) {
  data <- fetch_and_process_data(urls[[park]]$url, urls[[park]]$cols)
  colnames(data) <- dbSafeNames(colnames(data))
  dbWriteTable(con, park, data, append = TRUE, row.names = FALSE)
}

dbDisconnect(con)
