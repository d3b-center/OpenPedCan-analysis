# Calculate probe-level methylation values quantiles for all histologies (cancer types)

# Eric Wafula for Pediatric OpenTargets
# 10/18/2022

# Load libraries
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# set up optparse options
option_list <- list(
  make_option(opt_str = "--histologies", type = "character", default = NULL,
              help = "Histologies file",  
              metavar = "character"),
  make_option(opt_str = "--methyl_matrix", type = "character", default = NULL,
              help = "OPenPedCan methyl beta-values or m-values matrix file",
              metavar = "character"),
  make_option(opt_str = "--methyl_probe_annot", type = "character", default = NULL,
              help = "Methyl gencode array probe annotations",
              metavar = "character"),
  make_option(opt_str = "--independent_samples", type = "character", default = NULL,
              help = "OpenPedCan methyl independent biospecimen list file",
              metavar = "character"),
  make_option(opt_str = "--methyl_values", type = "character", default = "beta",
              help = "OPenPedCan methly matrix values: beta (default) and m", 
              metavar = "character")
)

# parse parameter options
opt <- parse_args(OptionParser(option_list = option_list))
histologies <- opt$histologies
methyl_matrix <- opt$methyl_matrix
methyl_probe_annot <- opt$methyl_probe_annot
independent_samples <- opt$independent_samples
methyl_values <- opt$methyl_values
stopifnot(methyl_values %in% c("beta","m"))

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module and results directories
data_dir <- file.path(root_dir, "data")
module_dir <- file.path(root_dir, "analyses", "methylation-summary")
results_dir <- file.path(module_dir, "results")

# get independent samples
independent_samples <-
  readr::read_tsv(independent_samples) %>%
  pull(Kids_First_Biospecimen_ID) %>%
  unique()

# Get required columns from histologies file for primary tumors
required_cols <- c("Kids_First_Biospecimen_ID", "cohort", "cancer_group")
histologies <- data.table::fread(histologies, sep = "\t", 
                                 select = required_cols, 
                                 showProgress = FALSE) %>% 
  tibble::as_tibble() %>% 
  dplyr::filter(!is.na(cancer_group),
    Kids_First_Biospecimen_ID %in% independent_samples)

# Get grch38 lifted methyl probe
lifted_probe_id <- readr::read_tsv(methyl_probe_annot) %>% 
  dplyr::pull(Probe_ID) %>% 
  unique()

# Get methyl values and only keep samples in independent sample list
methyl_matrix_df <- readr::read_rds(methyl_matrix) %>%
  dplyr::select(tidyselect::any_of(c("Probe_ID", independent_samples))) %>% 
  dplyr::filter(Probe_ID %in% lifted_probe_id)

# Calculating probe-level methyl values quantiles for all pre-processed samples
message("===============================================================")
message("Calculating probe-level methyl values quantiles for all samples")
message("===============================================================\n")

# Compute cancer type probe-level methyl values quantiles for all cohorts
index <- 0
methyl_quantiles_dfs <- list()
for (dataset in unique(histologies$cohort)) {
  cohort_histologies <- histologies %>% 
    dplyr::filter(cohort == dataset)
  for (cancer_type in unique(cohort_histologies$cancer_group)) {
    message(c("Calculating probe-level methyl values quantiles for ", dataset, ", ", cancer_type, " samples...\n"))
    index <- index + 1
    sample_ids <- cohort_histologies %>% 
      dplyr::filter(cancer_group == cancer_type) %>% 
      dplyr::pull(Kids_First_Biospecimen_ID) 
    quantiles <- methyl_matrix_df %>% 
      tibble::column_to_rownames(var = "Probe_ID") %>% 
      dplyr::select(any_of(sample_ids)) %>% 
      dplyr::filter(if_any(everything(), ~ !is.na(.))) %>% 
      apply(1, quantile, na.rm = TRUE) %>% t() %>% 
      tibble::as_tibble(rownames = "Probe_ID")
    if (methyl_values == "beta"){  
      quantiles <- quantiles %>% 
        dplyr::mutate(Dataset = dataset, Disease = cancer_type) %>%
        dplyr::rename("Beta_Q1" = "0%", "Beta_Q2" = "25%", "Beta_Median" = "50%", 
                      "Beta_Q4" = "75%", "Beta_Q5" = "100%")
    } else {
      quantiles <- quantiles %>% 
        dplyr::mutate(Dataset = dataset, Disease = cancer_type) %>%
        dplyr::rename("M_Q1" = "0%", "M_Q2" = "25%", "M_Median" = "50%",
                      "M_Q4" = "75%", "M_Q5" = "100%")
    }
    methyl_quantiles_dfs[[index]] <- quantiles
    rm(sample_ids, quantiles)
  }
  rm(cohort_histologies)
}
methyl_quantiles <- dplyr::bind_rows(methyl_quantiles_dfs)

# Write probe-level methyl_values quantiles to file
if (methyl_values == "beta"){ 
  message("Writing probe-level methyl values quantiles to methyl-probe-beta-quantiles.tsv file...\n")
  methyl_quantiles %>% data.table::setDT() %>%
  data.table::fwrite(file.path(results_dir, 
                               "methyl-probe-beta-quantiles.tsv.gz"), 
                     sep="\t", compress = "auto")
} else {
  message("Writing probe-level methyl values quantiles to methyl-probe-m-quantiles.tsv file...\n")
  methyl_quantiles %>% data.table::setDT() %>%
    data.table::fwrite(file.path(results_dir, 
                                 "methyl-probe-m-quantiles.tsv.gz"), 
                       sep="\t", compress = "auto")  
}

message("Analysis Done..\n")
