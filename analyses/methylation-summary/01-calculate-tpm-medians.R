# Calculate representative gene-level and isoform-level median expression for all 
# histologies (cancer types) using patients with both rnaseq and methyl data

# Eric Wafula for Pediatric OpenTargets
# 03/23/2023

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
  make_option(opt_str = "--rnaseq_matrix", type = "character", default = NULL,
              help = "OpenPedCan rnaseq tpm gene or isoform matrix file",
              metavar = "character"),
  make_option(opt_str = "--methyl_probe_annot", type = "character", default = NULL,
              help = "Methyl gencode array probe annotations",
              metavar = "character"),
  make_option(opt_str = "--methyl_independent_samples", type = "character", default = NULL,
              help = "OpenPedCan methyl independent biospecimen list file",
              metavar = "character"),
  make_option(opt_str = "--rnaseq_independent_samples", type = "character", default = NULL,
              help = "OpenPedCan rnaseq independent biospecimen list file",
              metavar = "character"),
  make_option(opt_str = "--exp_values", type = "character", default = "gene",
              help = "OpenPedCan expression matrix values: gene (default) and isoform", 
              metavar = "character")
)

# parse parameter options
opt <- parse_args(OptionParser(option_list = option_list))
histologies <- opt$histologies
rnaseq_matrix <- opt$rnaseq_matrix
methyl_probe_annot <- opt$methyl_probe_annot
methyl_independent_samples <- opt$methyl_independent_samples
rnaseq_independent_samples <- opt$rnaseq_independent_samples
exp_values <- opt$exp_values
stopifnot(exp_values %in% c("gene","isoform"))

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module and results directories
data_dir <- file.path(root_dir, "data")
module_dir <- file.path(root_dir, "analyses", "methylation-summary")
results_dir <- file.path(module_dir, "results")

# Create results directory if it doesn't exist
if (!dir.exists(results_dir)) {
  dir.create(results_dir)
}

# get independent samples
methyl_independent_samples <-
  readr::read_tsv(methyl_independent_samples) %>%
  pull(Kids_First_Biospecimen_ID) %>%
  unique()
rnaseq_independent_samples <-
  readr::read_tsv(rnaseq_independent_samples) %>%
  pull(Kids_First_Biospecimen_ID) %>%
  unique()

# Get required columns from histologies file for primary tumors
required_cols <- c("Kids_First_Biospecimen_ID", "Kids_First_Participant_ID", 
                   "cohort", "cancer_group")
histologies <- data.table::fread(histologies, sep = "\t", 
                                 select = required_cols, 
                                 showProgress = FALSE) %>% 
  tibble::as_tibble()

# Determine rnaseq samples for patient with both methyl data
methyl_histologies <- histologies %>% 
  dplyr::filter(!is.na(cancer_group),
    Kids_First_Biospecimen_ID %in% methyl_independent_samples) %>% 
  dplyr::rename(Meth_ID = Kids_First_Biospecimen_ID, 
                Patient_ID = Kids_First_Participant_ID,
                Dataset = cohort,
                Disease = cancer_group)
rnaseq_histologies <- histologies %>% 
  dplyr::filter(!is.na(cancer_group),
                Kids_First_Biospecimen_ID %in% rnaseq_independent_samples) %>% 
  dplyr::rename(RNASeq_ID = Kids_First_Biospecimen_ID, 
                Patient_ID = Kids_First_Participant_ID,
                Dataset = cohort,
                Disease = cancer_group) %>% 
  dplyr::inner_join(methyl_histologies, 
                    by = c("Patient_ID", "Dataset", "Disease")) %>% 
  dplyr::select(-Meth_ID) 

# Get methyl probe annotation
if (exp_values == "gene") {
  probe_annot <- readr::read_tsv(methyl_probe_annot) %>% 
    dplyr::select(targetFromSourceId, Gene_symbol) %>% 
    tidyr::drop_na() %>% 
    dplyr::distinct()
} else {
  probe_annot <- readr::read_tsv(methyl_probe_annot) %>% 
    dplyr::select(transcript_id) %>% 
    tidyr::drop_na() %>% 
    dplyr::distinct()
}

# Calculating representative gene-level and isoform-level median expression
message("=========================================================================")
message("Calculating representative gene-level and isoform-level median expression")
message("=========================================================================\n")

# Get tpm values and only keep samples with methyl data
if (exp_values == "gene") {
  # gene expression matrix
  rnaseq_matrix <- readr::read_rds(rnaseq_matrix) %>%
    dplyr::select(tidyselect::any_of(rnaseq_histologies$RNASeq_ID)) %>% 
    tibble::rownames_to_column(var = "Gene_symbol") %>% 
    dplyr::inner_join(probe_annot, by = "Gene_symbol") %>% 
    dplyr::select(-Gene_symbol) %>% 
    tidyr::pivot_longer(cols = -targetFromSourceId, names_to = "RNASeq_ID") %>%
    tidyr::pivot_wider(names_from = targetFromSourceId) %>% 
    dplyr::inner_join(rnaseq_histologies, by = "RNASeq_ID") %>% 
    dplyr::select(-RNASeq_ID, -Patient_ID) %>% 
    dplyr::group_by(Dataset, Disease) %>% 
    dplyr::summarise_all(median) %>% 
    dplyr::ungroup() %>% 
    tidyr::pivot_longer(cols = -c(Dataset, Disease), 
                        names_to = "targetFromSourceId", 
                        values_to = "Median_TPM") %>% 
    dplyr::distinct()
  
  # Write gene-level  median tpm expression to file
  message("Writing gene-level median tpm expression to gene-median-tpm-expression.tsv file...\n")
  rnaseq_matrix %>% data.table::setDT() %>%
      data.table::fwrite(file.path(results_dir,
                                   "gene-median-tpm-expression.tsv.gz"),
                         sep="\t", compress = "auto")
} else {
  # isoform expression matrix
  rnaseq_matrix <- readr::read_rds(rnaseq_matrix) %>%
    dplyr::select(tidyselect::any_of(
      c("transcript_id", rnaseq_histologies$RNASeq_ID))) %>%
    dplyr::mutate(transcript_id = 
                    stringr::str_extract(transcript_id, "ENST\\d+")) %>% 
    dplyr::inner_join(probe_annot, by = "transcript_id") %>% 
    tidyr::pivot_longer(cols = -transcript_id, names_to = "RNASeq_ID") %>%
    tidyr::pivot_wider(names_from = transcript_id) %>%
    dplyr::inner_join(rnaseq_histologies, by = "RNASeq_ID") %>%
    dplyr::select(-RNASeq_ID, -Patient_ID) %>%
    dplyr::group_by(Dataset, Disease) %>%
    dplyr::summarise_all(median) %>%
    dplyr::ungroup() %>%
    tidyr::pivot_longer(cols = -c(Dataset, Disease),
                        names_to = "transcript_id",
                        values_to = "Median_TPM") %>%
    dplyr::distinct() 
  
  # Write isoform-level  median tpm expression to file
  message("Writing gene-level median tpm expression to isoform-median-tpm-expression.tsv file...\n")
  rnaseq_matrix %>% data.table::setDT() %>%
    data.table::fwrite(file.path(results_dir,
                                 "isoform-median-tpm-expression.tsv.gz"),
                       sep="\t", compress = "auto")
}
  
message("Analysis Done..\n")
