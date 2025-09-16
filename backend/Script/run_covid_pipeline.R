args <- commandArgs(trailingOnly = TRUE)
working_dir <- args[1]
setwd(working_dir)
output_dir <- file.path(working_dir, "res")

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("📌 Working directory set to:", working_dir, "\n")
#setwd('/Users/boonhao/Documents/GitHub(personal)/test_BNM/bnm_workbench/backend/uploads/wenhao0117/COVID-19')
# Load dependencies
source("../../../Script/basic_functions.R")
source("../../../Script/api_key.R")
source("../../../Script/c19_modules/c19_equations.R")

# Step-by-step run each COVID-19 module
cat("🚀 Running: ID Generation\n")
source("../../../Script/c19_modules/NodeIDgenerator.R")

cat("🚀 Running: Human Node Quantification\n")
source("../../../Script/c19_modules/Human_node_quantification_Location_node_tabulation.R")
source("../../../Script/c19_modules/plotContactGraph.R")

cat("🚀 Running: Location Node Quantifica\n")
source("../../../Script/c19_modules/Location_node_quantification.R")

cat("🚀 Running: Formation of Contact Matrix and Link Weight Quantification\n")
source("../../../Script/c19_modules/Link_weight_quantificatin_CSM_formation.R")

cat("🚀 Running: Ranking Human and Location Node using HITS\n")
source("../../../Script/c19_modules/HITS_ranking_generation.R")

cat("✅ COVID-19 full pipeline completed.\n")
