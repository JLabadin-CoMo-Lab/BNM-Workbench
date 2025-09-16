
exist.location.ID <- retrieve_exLID()
names(exist.location.ID)


raw.contact.tracing <- read.table("contact_tracing.txt",sep = '\t',header = T)
raw.contact.tracing$Vector <- ifelse(grepl(',',raw.contact.tracing$Human),1,0)

if(length(intersect(unique(raw.contact.tracing$Location),exist.location.ID$Location))==0){
  new_loc <- unique(raw.contact.tracing$Location)
}else{
  new_loc <- setdiff(unique(raw.contact.tracing$Location),exist.location.ID$Location)
}


lastID <- nrow(exist.location.ID)
newID <- paste("L",c((lastID+1):(lastID+length(new_loc))),sep="")

a <- geocoding(new_loc)

new_loc_data <- data.frame(
  LID = newID,
  Location = new_loc,
  LatLng = sapply(a, paste,collapse=",")
)

new_loc.row <- data.frame(
  LID = newID,
  Location = new_loc,
  Building.Type = NA,
  LatLng = sapply(a, paste,collapse=","),
  Location.Type=NA,
  Q = NA
)

write.table(new_loc.row,file = "res/Location_ID.txt",sep = '\t', 
            append = TRUE, 
            quote = FALSE,
            row.names=F, 
            col.names=F)
write.table(new_loc.row,file = "res/Location_ID1.txt",sep = '\t', 
            append = TRUE, 
            quote = FALSE,
            row.names=F, 
            col.names=F)

update_loc.node <- read.table("res/Location_ID.txt",sep = '\t',header = TRUE)

raw.contact.tracing$Location.ID <- update_loc.node[match(raw.contact.tracing$Location,update_loc.node$LocationName),]$LID

write.table(raw.contact.tracing,file = "res/contact_tracing_LID.txt",sep = '\t', 
            quote = FALSE,
            row.names=FALSE, 
            col.names=TRUE)

#### HID generation
human_info <- read.table("human_meta.txt",sep = '\t',header = T)


exist.human.ID <- retrieve_exHID()
split_Human <- strsplit(raw.contact.tracing$Human,",")
split_Human <- unlist(lapply(split_Human, function(x) gsub(' ','',x)))
human_list <- unique(split_Human) 

if(length(intersect(human_list,exist.human.ID$HumanName))==0){
  new_hum <- human_list
}else{
  new_hum <- setdiff(human_list,exist.human.ID$HumanName)
}

lastID <- nrow(exist.human.ID)
newHID <- paste("H",c((lastID+1):(lastID+length(new_hum))),sep="")

newHID_df <- data.frame(HID=newHID,HumanName=new_hum,Hs=NA,caseID=NA)
newHID_df$Hs <- human_info[ match(newHID_df$HumanName,human_info$Name),'Hs']
newHID_df$caseID <- human_info[ match(newHID_df$HumanName,human_info$Name),'Belong']

write.table(newHID_df,file = "res/Human_ID.txt",sep = '\t', 
            append = TRUE, 
            quote = FALSE,
            row.names=F, 
            col.names=F)

