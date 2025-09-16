library(dplyr)
library(jsonlite)
library(stringr)

# --- Detect which module output exists ---
if (file.exists("res/hotspot_ranking.txt") && file.exists("res/LocationNode_list.txt")) {
  # ==========================
  # DENGUE MODULE
  # ==========================
  hotspot <- read.delim("res/hotspot_ranking.txt")
  location <- read.delim("res/LocationNode_list.txt")

  # Keep only one Lat/Lng per ClusterID
  location_clean <- location %>%
    select(ClusterID, Lat, Lng) %>%
    distinct()

  hotspot_json <- hotspot %>%
    left_join(location_clean, by = "ClusterID") %>%
    transmute(
      cluster = ClusterID,
      lat = Lat,
      lng = Lng,
      score = round(HubScore, 4)
    )

  write_json(hotspot_json, "res/hotspot.json", pretty = TRUE, auto_unbox = TRUE)
  cat("✅ Generated hotspot.json for Dengue module\n")

} else if (file.exists("res/Location_Node.txt") && file.exists("res/Location_ID.txt")) {
  # ==========================
  # COVID-19 MODULE
  # ==========================
  node <- read.delim("res/Location_Node.txt", stringsAsFactors = FALSE)
  locid <- read.delim("res/Location_ID.txt", stringsAsFactors = FALSE)

  # Join lat/lng from Location_ID
  node$LatLng <- locid$latlng[match(node$Location.ID, locid$LID)]
  node$lat <- as.numeric(str_extract(node$LatLng, "^[^,]+"))
  node$lng <- as.numeric(str_extract(node$LatLng, "[^,]+$"))

  # Define score (example: Ka + Ks, can be adjusted)
  node$score <- round(node$Ka + node$Ks, 4)

  hotspot_json <- node %>%
    transmute(
      cluster = Location.ID,
      lat = lat,
      lng = lng,
      score = score
    )

  write_json(hotspot_json, "res/hotspot.json", pretty = TRUE, auto_unbox = TRUE)
  cat("✅ Generated hotspot.json for COVID-19 module\n")

} else {
  stop("❌ No recognized input files found in res/. Cannot generate hotspot.json")
}

# library(dplyr)
# library(jsonlite)
# library(stringr)

# # Load files
# hotspot <- read.delim("res/hotspot_ranking.txt")
# location <- read.delim("res/LocationNode_list.txt")

# # Clean up location: keep only one Lat/Lng per ClusterID
# location_clean <- location %>%
#   select(ClusterID, Lat, Lng) %>%
#   distinct()

# # Merge
# hotspot_json <- hotspot %>%
#   left_join(location_clean, by = "ClusterID") %>%
#   transmute(
#     cluster = ClusterID,
#     lat = Lat,
#     lng = Lng,
#     score = round(HubScore, 4)
#   )

# # Write to JSON
# write_json(hotspot_json, "res/hotspot.json", pretty = TRUE, auto_unbox = TRUE)
