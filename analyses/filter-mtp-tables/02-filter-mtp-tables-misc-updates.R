# Perform miscellaneous updates on MTP table required by FNL
# Sangeeta Shukla for Pediatric OpenTargets
# 10/28/2022

# Load libraries
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(jsonlite))

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# Set up directories for input and output files
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
data_dir <- file.path(root_dir, "data")
scratch_dir <- file.path(root_dir, "scratch")
analyses_dir <- file.path(root_dir, "analyses")
module_dir <- file.path(analyses_dir, "filter-mtp-tables")
results_dir <- file.path(scratch_dir, "filter-mtp-tables") 


# Functions to perform misc updates
update_efo <- function(mtp_table) {
  # Update Wilms tumor EFO ID
  if ("Gene_Ensembl_ID" %in% colnames(mtp_table)) {
    mtp_table <- mtp_table %>%
      dplyr::mutate(EFO = 
                      replace(EFO, EFO == "MONDO_0006058",  "MONDO_0019004"),
                    MONDO = 
                      replace(MONDO, MONDO == "MONDO_0006058", "MONDO_0019004")
                    )
  } else {
    mtp_table <- mtp_table %>%
      dplyr::mutate(diseaseFromSourceMappedId = 
                      replace(diseaseFromSourceMappedId, 
                              diseaseFromSourceMappedId == "MONDO_0006058", 
                              "MONDO_0019004"),
                    MONDO = 
                      replace(MONDO, MONDO == "MONDO_0006058", "MONDO_0019004")
      )    
  }
  return(mtp_table)
}

remove_dgd_dna <- function(mtp_table) {
  # Remove all DGD samples
  mtp_table <- mtp_table %>%
    dplyr::filter(!Dataset == "CHOP P30 Panel")
  return(mtp_table)
}

write_to_file <- function(mtp_table, file_name) {
  # Write filtered TSV file
  mtp_table %>% readr::write_tsv(file.path(results_dir, file_name))
  # Write filtered JSON file
  json_file <- paste(unlist(str_split(file_name, "\\."))[1], "json", sep = ".")
  mtp_table %>% jsonlite::write_json(file.path(results_dir, json_file)) 
}

# Update gene-level snv frequencies
readr::read_tsv(file.path(results_dir, 
                          "gene-level-snv-consensus-annotated-mut-freq.tsv.gz"),
                guess_max = 10000) %>% 
  update_efo() %>% 
  remove_dgd_dna() %>% 
  write_to_file("gene-level-snv-consensus-annotated-mut-freq.tsv.gz")

# Update variant-level snv frequencies
readr::read_tsv(file.path(results_dir, 
                          "variant-level-snv-consensus-annotated-mut-freq.tsv.gz"),
                guess_max = 10000) %>% 
  update_efo() %>% 
  remove_dgd_dna() %>%
  write_to_file("variant-level-snv-consensus-annotated-mut-freq.tsv.gz")

# Update gene-level cnv frequencies
readr::read_tsv(file.path(results_dir, 
                          "gene-level-cnv-consensus-annotated-mut-freq.tsv.gz"),
                guess_max = 10000) %>% 
  update_efo() %>% 
  write_to_file("gene-level-cnv-consensus-annotated-mut-freq.tsv.gz")

# Update fusion frequencies
readr::read_tsv(file.path(results_dir, "putative-oncogene-fusion-freq.tsv.gz"),
                guess_max = 10000) %>% 
  update_efo() %>% 
  write_to_file("putative-oncogene-fusion-freq.tsv.gz")

# Update fused gene frequencies
readr::read_tsv(file.path(results_dir, "putative-oncogene-fused-gene-freq.tsv.gz"),
                guess_max = 10000) %>% 
  update_efo() %>% 
  write_to_file("putative-oncogene-fused-gene-freq.tsv.gz")


# Update tpm group-wise summary statistics
readr::read_tsv(file.path(results_dir, 
                          "long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz"),
                guess_max = 10000) %>% 
  update_efo() %>% 
  write_to_file("long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz")

# Update tpm gene-wise summary statistics
readr::read_tsv(file.path(results_dir, 
                          "long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz"),
                guess_max = 10000) %>% 
  update_efo() %>% 
  write_to_file("long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz")
  
