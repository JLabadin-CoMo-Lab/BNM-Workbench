library(tidygraph)
library(ggraph)
library(dplyr)

# === Load Edge List ===
df <- read.table("link_edge_list.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Rename to match "from" and "to"
edges <- df %>% select(from = PatientID, to = ClusterID)

# === Create Nodes with Type ===
nodes <- data.frame(name = unique(c(edges$from, edges$to))) %>%
  mutate(type = ifelse(grepl("^L", name), "Location", "Human"))

# === Build Graph ===
graph <- tbl_graph(nodes = nodes, edges = edges, directed = FALSE)

# === Plot ===
bnm_plot <- ggraph(graph, layout = "fr") +
  geom_edge_link(color = "grey") +
  geom_node_point(aes(color = type), size = 3) +
  geom_node_text(aes(label = name), repel = TRUE, size = 3) +
  scale_color_manual(values = c("Human" = "black", "Location" = "orange")) +
  theme_void()


