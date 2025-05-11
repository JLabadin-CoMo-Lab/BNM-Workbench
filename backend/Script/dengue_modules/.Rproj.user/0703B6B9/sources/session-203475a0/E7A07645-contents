library(dplyr)
library(matlib)

# === Step 1: Read input files ===
movement <- read.table("res/movement_list_with_LID.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE)
location <- read.table("res/location_list.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE)
cluster_env <- read.table("res/ClusterEnvParams.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE)

unique_ids <- unique(movement$ID)
human_id_map <- data.frame(
  ID = unique_ids,
  HumanNodeID = paste0("H", seq_along(unique_ids))
)

# Merge new HumanNodeID into movement
movement <- merge(movement, human_id_map, by = "ID")
# === Step 2: Merge ClusterID into movement ===
movement$VisitDate <- as.Date(movement$VisitDate, format = "%Y-%m-%d")
movement <- merge(movement, location[, c("LocationID", "ClusterID")], by = "LocationID", all.x = TRUE)

# === Step 3: Human Node Quantification ===
human_summary <- movement %>%
  group_by(HumanNodeID, ClusterID) %>%
  summarise(
    Fh = n(),
    D = sum(Duration),
    .groups = "drop"
  )

# Normalize Fh and D
human_summary <- human_summary %>%
  mutate(
    Fh_norm = (Fh / max(Fh)) * 0.9,
    D_norm  = (D / max(D)) * 0.9,
    qHuman_node = Fh_norm + D_norm
  )

# === Step 4: Location Node Quantification from ClusterEnvParams.txt ===
location_node <- cluster_env %>%
  mutate(
    Lc = (Lc / max(Lc)) * 0.9,
    S  = (S / max(S)) * 0.9,
    B  = (B / max(B)) * 0.9,
    Al = (Al / max(Al)) * 0.9,
    H  = (H / max(H)) * 0.9,
    Pre= (Pre / max(Pre)) * 0.9,
    Fl = (Fl / max(Fl)) * 0.9,
    qLocation_node = rowSums(across(c(Lc, S, B, Al, H, Pre, Fl)))
  )

# === Step 5: Link Weight Matrix ===
human_ids    <- unique(human_summary$HumanNodeID)
cluster_ids  <- unique(human_summary$ClusterID)

link_matrix <- matrix(0, nrow = length(cluster_ids), ncol = length(human_ids),
                      dimnames = list(cluster_ids, human_ids))

for (i in seq_along(cluster_ids)) {
  for (j in seq_along(human_ids)) {
    cid <- cluster_ids[i]
    pid <- human_ids[j]
    
    qh <- human_summary %>%
      filter(HumanNodeID == pid, ClusterID == cid) %>%
      pull(qHuman_node)
    
    ql <- location_node %>%
      filter(ClusterID == cid) %>%
      pull(qLocation_node)
    
    if (length(qh) == 0 || length(ql) == 0) {
      link_matrix[i, j] <- 0
    } else {
      link_matrix[i, j] <- qh + ql
    }
  }
}

# === Step 6: HITS (Hub and Authority Scores) ===
L <- link_matrix %*% t(link_matrix)  # cluster-cluster
H <- t(link_matrix) %*% link_matrix  # patient-patient

hub_init  <- rep(1, nrow(L))
auth_init <- rep(1, nrow(H))

hub_res  <- powerMethod(L, hub_init, eps = 1e-7, maxiter = 1000)
auth_res <- powerMethod(H, auth_init, eps = 1e-7, maxiter = 1000)

hub_scores  <- hub_res$vector / max(hub_res$vector)
auth_scores <- auth_res$vector / max(auth_res$vector)

# === Step 7: Hotspot Ranking ===
hotspots <- data.frame(
  ClusterID = rownames(link_matrix),
  HubScore = as.numeric(hub_scores)
)

hotspots <- hotspots[order(-hotspots$HubScore), ]

# === Step 7b: Patient Authority Ranking ===
authorities <- data.frame(
  PatientID = colnames(link_matrix),
  AuthorityScore = as.numeric(auth_scores)
)

authorities <- authorities[order(-authorities$AuthorityScore), ]

# === Step 7c: Create Edge List for Graphing ===
edge_list <- as.data.frame(as.table(link_matrix))
colnames(edge_list) <- c("ClusterID", "PatientID", "Weight")

# Filter out zero-weight edges (no interaction)
edge_list <- edge_list %>% filter(Weight > 0)

# Save edge list to file
write.table(edge_list, "res/link_edge_list.txt", sep = "\t", row.names = FALSE, quote = FALSE)


# === Step 8b: Write authority rankings to file ===
write.table(authorities, "res/patient_authority_ranking.txt", sep = "\t", row.names = FALSE, quote = FALSE)
# === Step 8: Write Outputs ===
write.table(hotspots, "res/hotspot_ranking.txt", sep = "\t", row.names = FALSE, quote = FALSE)
write.table(link_matrix, "res/link_weight_matrix.txt", sep = "\t", quote = FALSE)
write.table(human_summary, "res/human_node_quantification.txt", sep = "\t", row.names = FALSE, quote = FALSE)
write.table(location_node, "res/location_node_quantification.txt", sep = "\t", row.names = FALSE, quote = FALSE)
write.table(authorities, "res/patient_authority_ranking.txt", sep = "\t", row.names = FALSE, quote = FALSE)
write.table(human_id_map, "res/human_id_mapping.txt", sep = "\t", row.names = FALSE, quote = FALSE)

