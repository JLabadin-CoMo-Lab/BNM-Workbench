library(dplyr)


### Retrieve the quantified human node data, where the quantified human node data aldy prepared in network format
graph.Raw <- read.table("res/Human_Node.txt",sep = '\t',header = TRUE)

graph.Raw$nFh <- (graph.Raw$Fh/max(graph.Raw$Fh))*0.9
graph.Raw$nDu <- (graph.Raw$Du/max(graph.Raw$Du))*0.9
graph.Raw$nWR <- (graph.Raw$Pwr/max(graph.Raw$Pwr))*0.9

graph.Raw$qH <- graph.Raw$nFh + graph.Raw$nDu + graph.Raw$nWR
graph.Raw$qH_p <- graph.Raw$nFh * graph.Raw$nDu * graph.Raw$nWR


### Retrieve the quantified location node data

loc_node_param <- read.table("res/Location_Node.txt",sep = '\t',header = TRUE)

loc_node_param$nKa <- (loc_node_param$Ka/max(loc_node_param$Ka))*0.9
loc_node_param$nKs <- (loc_node_param$Ks/max(loc_node_param$Ks))*0.9
loc_node_param$nFl <- (loc_node_param$Fl/max(loc_node_param$Fl))*0.9
loc_node_param$qL  <- loc_node_param$nFl + loc_node_param$nKa + loc_node_param$nKs
loc_node_param$qL_p  <- loc_node_param$nFl * loc_node_param$nKa * loc_node_param$nKs
# write.table(loc_node_param,"467/normalized_LocNode.txt",sep = '\t',row.names = FALSE, col.names = TRUE, quote=FALSE)

names(graph.Raw)[1] <- "HID"
names(graph.Raw)[2] <- "LID"
lm_col <- unique(graph.Raw$HID)
lm_row <- unique(graph.Raw$LID)
cs_matrix <- matrix(nrow = length(lm_row),ncol = length(lm_col))
cs_matrix_p <- matrix(nrow = length(lm_row),ncol = length(lm_col))
colnames(cs_matrix) <- lm_col
rownames(cs_matrix) <- lm_row

colnames(cs_matrix_p) <- lm_col
rownames(cs_matrix_p) <- lm_row

for(m in 1:length(lm_row)){
  for(n in 1:length(lm_col)){
    qhuman <- graph.Raw %>% filter(LID == rownames(cs_matrix)[m],HID == colnames(cs_matrix)[n])
    #print(qhuman)
    if(nrow(qhuman)==0){
      cs_matrix[m,n] <- 0
      cs_matrix_p[m,n] <- 0
    }
    else{
      qlocation <- loc_node_param %>% filter(Location.ID == rownames(cs_matrix)[m])
      # print(qlocation)
      # print(c(rownames(cs_matrix)[m],colnames(cs_matrix)[n]))
      #print(qhuman$qHuman_node+location$qLocation_node)
      #print(round(qhuman$qH+qlocation$qL,digits = 4))
      cs_matrix[m,n] <- round(qhuman$qH+qlocation$qL,digits = 7)
      cs_matrix_p[m,n] <- round(qhuman$qH_p+qlocation$qL_p,digits = 7)
      
    }
  }
}

write.table(cs_matrix,"res/contact_matrix.txt",sep = '\t',row.names = TRUE, col.names = TRUE,quote = F)
