library(DBI)
library(RPostgres)
library(dplyr)

db_host <- Sys.getenv("DB_HOST")
db_port <- Sys.getenv("DB_PORT")
db_user <- Sys.getenv("DB_USER")
db_password <- Sys.getenv("DB_PASSWORD")
db_name <- Sys.getenv("DB_NAME")


# Connect to the PostgreSQL database
con <- dbConnect(RPostgres::Postgres(),
                 host = db_host,
                 port = db_port,
                 user = db_user,
                 password = db_password,
                 dbname = db_name)

#EPCOT
epcot_res <- "https://api.themeparks.wiki/v1/entity/47f90d2c-e191-4239-a466-5892ef59a88b/live"


ep_df <- epcot_res %>%
  jsonlite::fromJSON(flatten=TRUE)

ep_data <- ep_df$liveData

ep_data$time <- Sys.time()

ep_data <- ep_data[c(2:3, 6:7, 12:28)]

#Magic Kingdom
mk_res <- "https://api.themeparks.wiki/v1/entity/75ea578a-adc8-4116-a54d-dccb60765ef9/live"


mk_df <- mk_res %>%
  jsonlite::fromJSON(flatten=TRUE)

mk_data <- mk_df$liveData

mk_data$time <- Sys.time()

mk_data <- mk_data[c(2:3, 6,8, 12:27)]


#Hollywood Studios
hs_res <- "https://api.themeparks.wiki/v1/entity/288747d1-8b4f-4a64-867e-ea7c9b27bad8/live"


hs_df <- hs_res %>%
  jsonlite::fromJSON(flatten=TRUE)

hs_data <- hs_df$liveData

hs_data$time <- Sys.time()

hs_data <- hs_data[c(2:3, 6,8, 12:23)]


#Animal Kingdom
ak_res <- "https://api.themeparks.wiki/v1/entity/1c84a229-8862-4648-9c71-378ddd2c7693/live"


ak_df <- ak_res %>%
  jsonlite::fromJSON(flatten=TRUE)

ak_data <- ak_df$liveData

ak_data$time <- Sys.time()

ak_data <- ak_data[c(2:3, 6,7, 12:22)]


dbSafeNames = function(names) {
  names = gsub('[^a-z0-9]+','_',tolower(names))
  names = make.names(names, unique=TRUE, allow_=TRUE)
  names = gsub('.','_',names, fixed=TRUE)
  names
}

colnames(ep_data) = dbSafeNames(colnames(ep_data))
colnames(mk_data) = dbSafeNames(colnames(mk_data))
colnames(hs_data) = dbSafeNames(colnames(hs_data))
colnames(ak_data) = dbSafeNames(colnames(ak_data))


dbWriteTable(con, "epcot", ep_data, append = TRUE, row.names = FALSE)
dbWriteTable(con, "magic_kingdom", mk_data, append = TRUE, row.names = FALSE)
dbWriteTable(con, "hollywood_studios", hs_data, append = TRUE, row.names = FALSE)
dbWriteTable(con, "animal_kingdom", ak_data, append = TRUE, row.names = FALSE)



dbDisconnect(con)
