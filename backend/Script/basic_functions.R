toCheckDir <- function(uid){
  dir.create(uid, recursive = TRUE, showWarnings = FALSE)
  
  # Check if the sub-folder was created
  if (file.exists(uid)) {
    cat("Sub-folder created successfully.")
  } else {
    cat("Created")
  }
}

retrieve_exLID <- function(){
  file_path <- 'Location_ID.txt'
  
  # Check if file exists
  if (!file.exists(file_path)) {
    # Create an empty file
    # LID	LocationName latlng 
    write.table(data.frame(LID=character(),LocationName=character(),
                           Building.Type = character(),latlng=character(),Location.Type=character(), Q = character()), file = file_path, 
                sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
  }
  
  exist.location.ID <- read.table(file_path,sep = '\t',header = TRUE) 
  return(exist.location.ID)
}

geocoding <- function(loc){
  require(googleway)
  loc <- loc
  GAPIKey <- geocoding_key
  res <- lapply(loc,function(loc){
    google_geocode(address = loc,key = GAPIKey)
  })
  coords <- lapply(res, function(x){
    x$results$geometry$location
  })
}

retrieve_exHID <- function(){
  file_path <- 'Human_ID.txt'
  
  # Check if file exists
  if (!file.exists(file_path)) {
    # Create an empty file
    # LID	LocationName latlng 
    write.table(data.frame(HID=character(),HumanName=character(),
                           Hs = character(),caseID=character()), file = file_path, 
                sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
  }
  
  exist.location.ID <- read.table(file_path,sep = '\t',header = TRUE) 
  return(exist.location.ID)
}
