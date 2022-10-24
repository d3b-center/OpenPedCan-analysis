# Create combined methylation `Beta-values` and `M-values` matrices for all
# histologies (cancer types)

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

# Get primary tumor methylation sample IDs
required_cols <- c("Kids_First_Biospecimen_ID", "Kids_First_Participant_ID", 
                   "experimental_strategy", "sample_type", "tumor_descriptor",
                   "cohort", "cancer_group")
primary_tumors <- data.table::fread(file.path(data_dir, "histologies.tsv"), 
                                 sep = "\t", 
                                 select = required_cols, 
                                 showProgress = FALSE) %>% 
  tibble::as_tibble() %>% 
  dplyr::filter(experimental_strategy == "Methylation") %>% 
  dplyr::pull(Kids_First_Biospecimen_ID)

# Get array annotation probes corresponding to GENCODE version 38 (Ensembl 104) 
# gene symbols
annot_file <- file.path(results_dir, 
                        "methyl-probe-annotations.tsv.gz")
probe_ids <- data.table::fread(annot_file, select = "Probe_ID", 
                               showProgress = FALSE) %>% 
  dplyr::distinct() %>% 
  dplyr::pull(Probe_ID)

# Function to create methylation matrix
create_matrix <- function(meth_file, probe_ids) {
  required_cols <- c("Probe", "Sample_Name", "Meth_Value")
  meth_table <- data.table::fread(meth_file, 
                                  select = required_cols, 
                                  showProgress = FALSE) %>% 
    tibble::tibble() %>% 
    dplyr::rename(Probe_ID = Probe) %>% 
    tidyr::pivot_wider(names_from = Sample_Name, values_from = Meth_Value) %>% 
    dplyr::filter(Probe_ID %in% probe_ids)
  return(meth_table)
}

# Creating Beta-values matrix for all  preprocessed methylation samples
message("===================================================================")
message(c("Creating merged Beta-values matrix for all methylation samples"))
message("===================================================================\n")

# TARGET beta-values samples
message("Creating Beta-values matrix for TARGET samples...\n")
target_matrix <- create_matrix(
  file.path(data_dir, "TARGET-beta-values-methylation.tsv.gz"), probe_ids) %>%
  # add ".M" to TARGET methylation samples to avoid conflicts with WXS samples
  dplyr::rename_with(.fn = ~ paste0(., ".M"), .cols = starts_with("TARGET-"))

# CBTN beta-values samples 
message("Creating Beta-values matrix for CBTN samples...\n")
cbtn_matrix <- create_matrix(
  file.path(data_dir, "CBTN-beta-values-methylation.tsv.gz"), probe_ids)
beta_matrix <- target_matrix %>% dplyr::full_join(cbtn_matrix, by = "Probe_ID")
rm(target_matrix, cbtn_matrix)

# write merged beta-values to file
message("Writing merged Beta-values matrix to methyl-beta-values.rds file...\n")
beta_matrix %>% dplyr::select(tidyselect::any_of(c("Probe_ID", primary_tumors))) %>% 
  readr::write_rds(file.path(results_dir, "methyl-beta-values.rds"))
rm(beta_matrix)

# Creating M-values matrix for all methylation samples
message("=================================================================")
message("Creating merged M-values matrix for all methylation samples")
message("=================================================================\n")

# TARGET m-values samples
message("Creating M-values matrix for TARGET samples...\n")
target_matrix <- create_matrix(
  file.path(data_dir, "TARGET-m-values-methylation.tsv.gz"), probe_ids) %>%
  # add ".M" to TARGET methylation samples to avoid conflicts with WXS samples
  dplyr::rename_with(.fn = ~ paste0(., ".M"), .cols = starts_with("TARGET-"))

# CBTN m-values samples 
message("Creating M-values matrix for CBTN samples...\n")
cbtn_matrix <- create_matrix(
  file.path(data_dir, "CBTN-m-values-methylation.tsv.gz"), probe_ids)
m_matrix <- target_matrix %>% dplyr::full_join(cbtn_matrix, by = "Probe_ID")
rm(target_matrix, cbtn_matrix)

# write merged m-values to file
message("Writing merged M-values matrix to methyl-m-values.rds file...\n")
m_matrix %>% dplyr::select(tidyselect::any_of(c("Probe_ID", primary_tumors))) %>% 
  readr::write_rds(file.path(results_dir, "methyl-m-values.rds"))
rm(m_matrix)

message("Analysis Done..\n")