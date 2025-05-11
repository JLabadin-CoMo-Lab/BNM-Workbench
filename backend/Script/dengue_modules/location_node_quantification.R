library(httr)
library(jsonlite)
library(lubridate)
library(dplyr)
# === CONFIG ===
weather_key <- "c426f50d415e4322b7543805221504"
output_file <- "res/ClusterEnvParams.txt"

# === Step 1: Read input files ===
movement <- read.table("res/movement_list_with_LID.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE)
location <- read.table("res/location_list.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# === Step 2: Merge ClusterID into movement data ===
movement$VisitDate <- as.Date(movement$VisitDate, format = "%Y-%m-%d")
movement <- merge(movement, location[, c("LocationID", "ClusterID")], by = "LocationID", all.x = TRUE)

# === Step 3: Process each cluster ===
cluster_ids <- unique(movement$ClusterID)
env_param_list <- list()

for (cid in cluster_ids) {
  visits <- movement %>% filter(ClusterID == cid)
  visit_dates <- as.Date(visits$VisitDate)
  
  node_info <- location[location$ClusterID == cid, ]
  lat <- node_info$Lat[1]
  lng <- node_info$Lng[1]
  ele <- node_info$Elevation[1]
  
  temp_all <- humi_all <- prec_all <- c()
  
  for (d in visit_dates) {
    q <- paste(lat, lng, sep = ",")
    
    # Safe API request with error handling
    r <- tryCatch({
      GET("http://api.worldweatheronline.com/premium/v1/past-weather.ashx",
          query = list(
            key = weather_key,
            q = q,
            format = "json",
            date = format(as.Date(d) - 14, "%Y-%m-%d"),
            enddate = format(as.Date(d) - 1, "%Y-%m-%d"),
            tp = 24
          ))
    }, error = function(e) {
      message(paste("Error in API request for date:", as.character(d)))
      message(e)
      return(NULL)  # Return NULL in case of error
    })
    
    # Check if the response is valid
    if (is.null(r) || status_code(r) != 200) {
      message(paste("Failed to fetch weather data for:", as.character(d)))
      message("Status code:", status_code(r))
      next  # Skip to the next date if there's an error
    }
    
    # Parse the response
    raw_data <- tryCatch({
      fromJSON(content(r, as = "text", encoding = "UTF-8"))
    }, error = function(e) {
      message(paste("Error parsing JSON for date:", as.character(d)))
      return(NULL)  # Return NULL in case of JSON parsing error
    })
    
    if (is.null(raw_data) || is.null(raw_data$data$weather)) {
      message(paste("Malformed data for date:", as.character(d)))
      next  # Skip this iteration if data is malformed
    }
    
    weather_days <- raw_data$data$weather
    
    # Safely extract temperature, humidity, and precipitation data
    temp_vec <- as.numeric(weather_days$avgtempC)
    humi_vec <- sapply(weather_days$hourly, function(h) as.numeric(h$humidity[1]))
    prec_vec <- sapply(weather_days$hourly, function(h) as.numeric(h$precipMM[1]))
    
    temp_all <- c(temp_all, mean(as.numeric(temp_vec)))
    humi_all <- c(humi_all, mean(as.numeric(humi_vec)))
    prec_all <- c(prec_all, mean(as.numeric(prec_vec)))
  }
  
  T <- mean(temp_all)
  H <- mean(humi_all)
  Pre <- mean(prec_all)
  Al <- as.numeric(ele)
  
  # Life cycle duration (Lc)
  tLc <- (T - 30.125) / 8.708575
  Lc <- (0.8330)*(tLc^5)+(5.6167*(tLc^4))+(2.7984*(tLc^3))+(0.0462*(tLc^2))-(4.4171*tLc)+6.8194
  
  # Survival rate (S)
  tSr <- (T - 23) / 8.485281
  S <- 52.0815*tSr^6 - 11.0494*tSr^5 - 144.7057*tSr^4 + 49.4932*tSr^3 + 48.5714*tSr^2 - 5.2862*tSr + 86.3452
  
  # Biting rate (B)
  B <- if (T >= 21 && T <= 32) 0.03 * T + 0.66 else 0.8
  
  # Frequency (Fl)
  Fl <- nrow(visits)
  
  env_param_list[[cid]] <- data.frame(
    ClusterID = cid,
    T = T, H = H, Pre = Pre, Al = Al,
    Lc = 1/Lc, S = S, B = B, Fl = Fl,
    stringsAsFactors = FALSE
  )
}

# === Step 4: Save final output ===
env_table <- do.call(rbind, env_param_list)
write.table(env_table, output_file, sep = "\t", row.names = FALSE, quote = FALSE)
