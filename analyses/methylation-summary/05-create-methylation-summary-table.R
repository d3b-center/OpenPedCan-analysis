# Create Pediatric OpenTargets methylation summary table that will be utilized
# with OPenPedCan plotting API and displayed on the NCI MTP portal

# Eric Wafula for Pediatric OpenTargets
# 03/18/2022

# Load libraries
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(ids))

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module and results directories
data_dir <- file.path(root_dir, "data")
analyses_dir <- file.path(root_dir, "analyses")
module_dir <- file.path(root_dir, "analyses", "methylation-summary")
results_dir <- file.path(module_dir, "results")

# Creating Pediatric OpenTargets methylation summary table
message("==========================================================")
message("Creating Pediatric OpenTargets methylation summary table")
message("==========================================================\n")

# Create methylation summary table by merging methylation array probe quantiles 
# and beta-tpm correlations tables
message("Merging probe-level quantiles and beta-tpm correlations...\n")
beta_tpm_correlations <- data.table::fread(
  file.path(results_dir, "methyl-probe-beta-tpm-correlations.tsv.gz"),
  showProgress = FALSE) %>% 
  tibble::as_tibble()
summary_table <- data.table::fread(
  file.path(results_dir, "methyl-probe-beta-quantiles.tsv.gz"), 
  showProgress = FALSE)  %>% 
  tibble::as_tibble() %>% 
  dplyr::left_join(beta_tpm_correlations, by = c("Probe_ID", "Dataset", "Disease"))
rm(beta_tpm_correlations)

# Add GENCODE version 38 (Ensembl 104) gene symbols and Ensembl IDs probe 
# annotation to the the methylation summary table
message("Including gene symbols and Ensembl probe annotations ...\n")
summary_table <- data.table::fread(
  file.path(results_dir, "methyl-probe-annotations.tsv.gz"),
  showProgress = FALSE) %>% 
  tibble::as_tibble() %>% 
  dplyr::right_join(summary_table, by = "Probe_ID")

# Add PMTL disgnation corresponding to GENCODE version 38 (Ensembl 104) gene
# symbols and Ensembl IDs
message("Including PMTL disgnation for corresponding Ensembl IDs ...\n")
pmtl_ensembl_ids <- readr::read_tsv(file.path(data_dir, 
                                              "ensg-hugo-pmtl-mapping.tsv"),
                           show_col_types = FALSE) %>% 
  dplyr::filter(pmtl == "Non-Relevant Molecular Target" | pmtl == "Relevant Molecular Target") %>% 
  dplyr::pull(ensg_id) %>% unique() 
summary_table <- summary_table %>% 
  dplyr::mutate(PMTL = case_when(
    targetFromSourceId %in% pmtl_ensembl_ids ~ "Relevant Molecular Target"))

# Add EFO and MONDO codes associated with cancer type (Disease)
message("Including EFO and MONDO codes associated with cancer types ...\n")
summary_table <- readr::read_tsv(file.path(data_dir, "efo-mondo-map.tsv"),
                                    show_col_types = FALSE) %>% 
  dplyr::distinct() %>% 
  dplyr::rename(Disease = cancer_group, MONDO = mondo_code,
                diseaseFromSourceMappedId = efo_code) %>% 
  dplyr::right_join(summary_table, by = "Disease")
  

# Add additional columns required for the OT portal
message("Including additional metadata required for the NCI MTP portal ...\n")
uuid_strings <- ids::uuid(nrow(summary_table))
stopifnot(length(unique(uuid_strings)) == nrow(summary_table))
summary_table <-  summary_table %>% 
  dplyr::select(Gene_symbol, targetFromSourceId, PMTL, Dataset, Disease,  
                diseaseFromSourceMappedId, MONDO, RNA_Correlation, Probe_ID, 
                Chromosome, Location, Beta_Q1, Beta_Q2, Beta_Median, Beta_Q4, 
                Beta_Q5) %>% 
  dplyr::mutate(datatypeId = "Illumina_methylation_array",
                chop_uuid = uuid_strings, 
                datasourceId = "chop_gene_level_methylation")

# Write methylation summary table to RDS file - needed for API DB loading
message("Writing methylation summary table to methyl-beta-values-summary.rds file...\n")
summary_table %>% 
  readr::write_rds(file.path(results_dir, "methyl-beta-values-summary.rds"))

# Write methylation summary table to TSV file - need for MPT user download
message("Writing methylation summary table to methyl-beta-values-summary.tsv file...\n")
summary_table %>% data.table::setDT() %>%
  data.table::fwrite(file.path(results_dir,
                               "methyl-beta-values-summary.tsv.gz"), 
                     sep="\t", compress = "auto")
  
message("Analysis Done..\n")