library(matlib)

cs_matrix <- as.matrix(read.table('contact_matrix.txt',sep = '\t'))
l <-  as.matrix(cs_matrix)%*%t(cs_matrix)
lsize <- nrow(l)
#write.table(l,"467a/Loc_UCN_contact_matrix.txt",sep = '\t',row.names = TRUE,col.names = TRUE)

# auth(patient)
h <-  t(cs_matrix)%*%as.matrix(cs_matrix)
hsize <- nrow(h)
#write.table(h,"467a/Hum_UCN_contact_matrix.txt",sep = '\t',row.names = TRUE,col.names = TRUE)

auth <- c(rep(1,hsize))
hub <- c(rep(1,lsize))

# epsilon = 0.0000001 & maximum iteration = 1000 (stopping criteria)
il <- powerMethod(l,hub,eps = 10^-7, maxiter = 1000)
ih <- powerMethod(h,auth,eps = 10^-7, maxiter = 1000)

# Normalize eigen values
vl <- il$vector/max(il$vector)
vh <- ih$vector/max(ih$vector)
colnames(vl) <- 'DHR Value'
colnames(vh) <- 'Ranking Value'

##################################################

##HOTSPOT##

hotspot <- data.frame(
  Lid = rownames(vl),
  CHR = as.numeric(vl),
  ranking = as.numeric(factor(rank(-vl)))
)


human_rank <- data.frame(
  HID = rownames(vh),
  CRR = as.numeric(vh),
  ranking = as.numeric(factor(rank(-vh)))
)

hotspot <- hotspot[order(hotspot$ranking),]
human_rank <- human_rank[order(human_rank$ranking),]


write.table(hotspot,'hotspot.txt',sep = '\t',row.names = FALSE,col.names = TRUE,quote = F)
write.table(human_rank,'human_rank.txt',sep = '\t',row.names = FALSE,col.names = TRUE, quote = F)
