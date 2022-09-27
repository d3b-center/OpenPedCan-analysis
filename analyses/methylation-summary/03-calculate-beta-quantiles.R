# Calculate probe-level beta quantiles for all histologies (cancer types)

# Eric Wafula for Pediatric OpenTargets
# 03/18/2022

# Load libraries
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module and results directories
data_dir <- file.path(root_dir, "data")
module_dir <- file.path(root_dir, "analyses", "methylation-summary")
results_dir <- file.path(module_dir, "results")

# Get required columns from histologies file for primary tumors
required_cols <- c("Kids_First_Biospecimen_ID", "Kids_First_Participant_ID", 
                   "experimental_strategy", "sample_type", "tumor_descriptor",
                   "cohort", "cancer_group")
histologies <- data.table::fread(file.path(data_dir, "histologies.tsv"), 
                                 sep = "\t",
                                 select = required_cols, 
                                 showProgress = FALSE) %>% 
  tibble::as_tibble() %>% 
  dplyr::filter(sample_type == "Tumor" & 
                  (tumor_descriptor == "Primary Tumor" | 
                     tumor_descriptor == "Initial CNS Tumor") & 
                  experimental_strategy == "Methylation")
  
# Get methylation beta values
beta <- readr::read_rds(file.path(results_dir, "methyl-beta-values.rds"))

# Calculating probe-level beta quantiles all preprocessed methylation samples
message("===================================================================")
message("Calculating probe-level beta quantiles for all methylation samples")
message("===================================================================\n")

# Compute cancer type probe-level beta quantiles for all cohorts
index <- 0
beta_quantiles_dfs <- list()
for (dataset in unique(histologies$cohort)) {
  cohort_histologies <- histologies %>% 
    dplyr::filter(cohort == dataset)
  for (cancer_type in unique(cohort_histologies$cancer_group)) {
    message(c("Calculating probe-level beta quantiles for ", dataset, ", ", cancer_type, " samples...\n"))
    index <- index + 1
    sample_ids <- cohort_histologies %>% 
      dplyr::filter(cancer_group == cancer_type) %>% 
      dplyr::pull(Kids_First_Biospecimen_ID) 
    quantiles <- beta %>% 
      tibble::column_to_rownames(var = "Probe_ID") %>% 
      dplyr::select(any_of(sample_ids)) %>% 
      dplyr::filter(if_any(everything(), ~ !is.na(.))) %>% 
      apply(1, quantile, na.rm = TRUE) %>% t() %>% 
      tibble::as_tibble(rownames = "Probe_ID")  %>%
      dplyr::mutate(Dataset = dataset, Disease = cancer_type) %>%
      dplyr::rename("Beta_Q1" = "0%", "Beta_Q2" = "25%", "Beta_Median" = "50%",
                    "Beta_Q4" = "75%", "Beta_Q5" = "100%")
    beta_quantiles_dfs[[index]] <- quantiles
    rm(sample_ids, quantiles)
  }
  rm(cohort_histologies)
}
beta_quantiles <- dplyr::bind_rows(beta_quantiles_dfs)

# Write probe-level beta quantiles to file
message("Writing probe-level beta quantile to methyl-probe-beta-quantiles.tsv file...\n")
beta_quantiles %>% data.table::setDT() %>%
  data.table::fwrite(file.path(results_dir,
                               "methyl-probe-beta-quantiles.tsv.gz"), 
                     sep="\t", compress = "auto")

message("Analysis Done..\n")
