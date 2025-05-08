library(tidyverse)

#########Human node quantification#####################


raw <- read.table("contact_tracing_LID.txt",sep = '\t',header = TRUE)

bip.graph.raw <- as.data.frame(raw %>% group_by(Human,Location.ID,Vector)%>%summarise(Fh=n(),Du=sum(D)))
pos.to.remove <- which(bip.graph.raw$Vector==1)
unlist.bip.graph.raw <- bip.graph.raw[pos.to.remove,]

split_HID <- strsplit(unlist.bip.graph.raw$Human,",")

split_HID <- lapply(split_HID, function(x) gsub(' ','',x))
unique_HID <- unique(unlist(split_HID))

unlist.human.len <- lengths(split_HID)
unlist.bip.graph.raw$Fre <- unlist.human.len

unlist.bip.graph.raw.2 <- unlist.bip.graph.raw[rep(1:nrow(unlist.bip.graph.raw),unlist.bip.graph.raw[["Fre"]]),]

if(length(unlist(split_HID))==nrow(unlist.bip.graph.raw.2)){
  new.HID <- unlist(split_HID)
  unlist.bip.graph.raw.2$Human <- new.HID
  unlist.bip.graph.raw.2 <- unlist.bip.graph.raw.2[,-6]#remove Fre column
  bip.graph.raw <- bip.graph.raw[-c(pos.to.remove),]# remove the row where the vector==1
  bip.graph <- rbind(bip.graph.raw,unlist.bip.graph.raw.2)
}else{
  print("Length of HID didn't match with numer of row")
}



exist.location.ID <- read.table("Location_ID.txt",sep = '\t',header = TRUE)

human.ID <- read.table("Human_ID.txt",sep = '\t',header = TRUE)
bip.graph$Human.ID <- human.ID[ match(bip.graph$Human,human.ID$HumanName),'HID']

bip.graph$Hs <- human.ID[match(bip.graph$Human.ID,human.ID$HID),'Hs']
#Q_Ltype <- exist.location.ID[match(bip.graph$Location.ID,exist.location.ID$LID),c(5,6)]
bip.graph$Q <- 1
bip.graph$Location.Type <- 1#Q_Ltype$Location.Type
for(i in 1:nrow(bip.graph)){
  bip.graph$Pwr[i] <- Pwr(bip.graph[i,])
}
bip.graph <- as.data.frame(bip.graph %>% group_by(Human,Location.ID)%>%summarise(Fh=sum(Fh),Du=sum(Du), Pwr=mean(Pwr)))
write.table(bip.graph,"Human_Node.txt",sep = '\t',row.names = FALSE,col.names = TRUE,quote = FALSE)


#########Human node quantification END#####################

#### Form Location Table ###################################
# Hs.HID <- human.ID[match(unique_HID,human.ID$HID),c(3,8)]
# infec.ID <- Hs.HID[Hs.HID$Hs==1,]$HID  
loc_node <- as.data.frame(raw %>% group_by(Location.ID)%>%summarise(Fl=n(),Date=list(Date)))
loc_node.write <- loc_node
loc_node.write$Date <- vapply(loc_node.write$Date, paste,  collapse = ", ", character(1L))
write.table(loc_node.write,"Location_Node.txt",sep = '\t',row.names = FALSE,col.names = TRUE,quote = FALSE)

