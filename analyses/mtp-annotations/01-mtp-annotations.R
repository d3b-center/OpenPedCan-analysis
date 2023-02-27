# Create MTP Open Targets diseases and targets annotation mappings
# David Hill and Eric Wafula for Pediatric OpenTargets
# 02/14/2023

# Load libraries
suppressPackageStartupMessages(library(tidyverse))

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to scratch, module and results directories
scratch_dir <- file.path(root_dir, "scratch")
module_dir <- file.path(root_dir, "analyses", "mtp-annotations")
results_dir <- file.path(module_dir, "results")

# Create results directory if it doesn't exist
if (!dir.exists(results_dir)) {
  dir.create(results_dir)
}

# load diseases csv files and write annotation mappings to file 
diseases_dir <- file.path(scratch_dir, "mtp-csv", "diseases")
list.files(diseases_dir, pattern = ".csv", full.names = TRUE) %>% 
  purrr::map(~ readr::read_csv(.x)) %>% 
  dplyr::bind_rows() %>% 
  dplyr::select(id, name, description, dbXRefs) %>% 
  dplyr::distinct() %>% 
  readr::write_tsv(file.path(results_dir, "mtp-diseases-mapping.tsv.gz"))

# load targets csv files and write annotation mappings to file 
targets_dir <- file.path(scratch_dir, "mtp-csv", "targets")
list.files(targets_dir, pattern = ".csv", full.names = TRUE) %>% 
  purrr::map(~ readr::read_csv(.x)) %>% 
  dplyr::bind_rows() %>% 
  dplyr::select(approvedSymbol, id, transcriptIds) %>%
  dplyr::mutate(transcriptIds = gsub("\\[|\\]", "", transcriptIds)) %>%
  tidyr::separate_rows(transcriptIds) %>% 
  dplyr::rename(gene_symbol = approvedSymbol, gene_id = id, 
                transcript_id = transcriptIds) %>% 
  dplyr::distinct() %>% 
  readr::write_tsv(file.path(results_dir, "mtp-targets-mapping.tsv.gz"))
