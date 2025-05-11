library(dplyr)
library(jsonlite)
library(stringr)

# Load files
hotspot <- read.delim("res/hotspot_ranking.txt")
location <- read.delim("res/LocationNode_list.txt")

# Clean up location: keep only one Lat/Lng per ClusterID
location_clean <- location %>%
  select(ClusterID, Lat, Lng) %>%
  distinct()

# Merge
hotspot_json <- hotspot %>%
  left_join(location_clean, by = "ClusterID") %>%
  transmute(
    cluster = ClusterID,
    lat = Lat,
    lng = Lng,
    score = round(HubScore, 4)
  )

# Write to JSON
write_json(hotspot_json, "res/hotspot.json", pretty = TRUE, auto_unbox = TRUE)
