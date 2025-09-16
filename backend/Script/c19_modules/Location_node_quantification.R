library(httr)
library(jsonlite)

key <-'c426f50d415e4322b7543805221504' #Weather API key


exist.location.ID <- read.table("res/Location_ID.txt",sep = '\t',header = TRUE)
loc.raw <- read.table("res/Location_Node.txt",sep = '\t',header = TRUE)

loc.raw$LatLng <- exist.location.ID[match(loc.raw$Location.ID,exist.location.ID$LID),'latlng']
loc.raw$T <- NA
loc.raw$H <- NA
loc.raw$Ka <-NA
loc.raw$Ks <-NA

for(i in 1:nrow(loc.raw)){
  Ks <- c()
  Ka <- c()
  T <- c()
  H <- c()
  date <- unlist(strsplit(loc.raw$Date[i],","))
  
  for(j in 1:length(date)){
    q <- enc2utf8(loc.raw$LatLng[i])  
    r <- GET("http://api.worldweatheronline.com/premium/v1/past-weather.ashx?",
             query = list(key = key, q = q,format='json', date = as.Date(date[j],format="%m/%d/%y"),tp=24))
    res <- content(r)
    weatherList <- res$data$weather
    T1 <- as.numeric(weatherList[[1]]$avgtempC)
    H1 <- as.numeric(weatherList[[1]]$hourly[[1]]$humidity)
    Ka[j] <- ka(T1,H1)
    Ks[j] <- ks(T1,H1)
    T[j] <- T1
    H[j] <- H1
  }
  loc.raw$Ka[i] <- sum(Ka)
  loc.raw$Ks[i] <- sum(Ks)
  loc.raw$T[i] <- mean(T)
  loc.raw$H[i] <- mean(H)
}

write.table(loc.raw,"res/Location_Node.txt",sep = '\t',row.names = FALSE,col.names = TRUE,quote = FALSE)
write.table(loc.raw,"res/Location_Node2.txt",sep = '\t',row.names = FALSE,col.names = TRUE,quote = FALSE)

