# Author: Jo Lynne Rokita
# Function: Script to subtype MB tumors and all associated bs_ids from either MB RNA-Seq classifier results or methylation classifier results

suppressPackageStartupMessages({
  library(tidyverse)
})

# root directory
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# set results directory
analysis_dir <- file.path(root_dir, "analyses", "molecular-subtyping-MB") 
output_dir <- file.path(analysis_dir, "results") 
input_dir <- file.path(analysis_dir, "input") 

# create results file
results_file <- "MB_molecular_subtype.tsv"

# add pathological diagnosis json file
path_dx_list <- jsonlite::fromJSON(file.path(input_dir, "mb_subtyping_path_dx_strings.json"))

# read medulloblastoma samples from clinical file created in script 01
mb_biospecimens <- read_tsv(file.path(input_dir, "subset-mb-clinical.tsv"))
nrow(mb_biospecimens)

# how many patients? 
mb_pts <- mb_biospecimens %>%
  pull(Kids_First_Participant_ID) %>%
  unique()
length(mb_pts)

# start with samples which had RNA subtyped ------------------
# read in medulloPackage results and recode
mb_rna_results <- readRDS(file.path(output_dir, "mb-classified.rds"))$medulloPackage %>%
  dplyr::rename(Kids_First_Biospecimen_ID = sample,
                molecular_subtype = best.fit) %>%
  # format subtype result
  mutate(molecular_subtype = paste0("MB, ", molecular_subtype)) %>%
  select(Kids_First_Biospecimen_ID, molecular_subtype) %>%
  left_join(mb_biospecimens[,c("Kids_First_Biospecimen_ID", "match_id")]) %>%
  select(-Kids_First_Biospecimen_ID) %>%
  unique()

# are there discrepancies? yes
length(unique(mb_rna_results$match_id)) == nrow(mb_rna_results)

# we will add methyl subtypes in the absence of RNA-Seq classification or in the case of discrepant classifier results
methyl_mb_subtypes <- mb_biospecimens %>%
  filter(str_detect(str_to_lower(pathology_diagnosis), path_dx_list$include_free_text), 
         experimental_strategy == "Methylation",
         (grepl("MB_", dkfz_v12_methylation_subclass) & dkfz_v12_methylation_subclass_score >= 0.8)) %>%
  # reformat classifier result per https://www.molecularneuropathology.org/mnp/classifiers/11
  mutate(molecular_subtype_methyl = case_when(grepl("MB_SHH", dkfz_v12_methylation_subclass) ~ "MB, SHH",
                                       dkfz_v12_methylation_subclass %in% c("MB_G34_I", "MB_G34_II", "MB_G34_III", "MB_G34_IV") ~ "MB, Group3",
                                       dkfz_v12_methylation_subclass %in% c("MB_G34_V", "MB_G34_VI", "MB_G34_VII", "MB_G34_VIII") ~ "MB, Group4",
                                       dkfz_v12_methylation_subclass == "MB_WNT" ~ "MB, WNT",
                                       dkfz_v12_methylation_subclass == "MB_MYO" ~ "MB, MYO")) %>%
  dplyr::select(match_id, molecular_subtype_methyl) %>%
  unique()

# are there discrepancies? no
length(unique(methyl_mb_subtypes$match_id)) == nrow(methyl_mb_subtypes)

# combine
mb_rna_methyl <- mb_rna_results %>%
  full_join(methyl_mb_subtypes) %>%
  # fill in methyl to NA molecular subtype
  mutate(molecular_subtype = case_when(is.na(molecular_subtype) ~ molecular_subtype_methyl,
                                       TRUE ~ molecular_subtype))

# 1 discrepant subtype pair from RNA results, let's fix it
dups <- mb_rna_methyl %>%
  filter(duplicated(.[["match_id"]])) 

if (nrow(dups) > 0) {
  mb_rna_methyl_dups_rm <- mb_rna_methyl %>%
  mutate(molecular_subtype = case_when(match_id %in% dups$match_id ~ molecular_subtype_methyl,
                                       TRUE ~ as.character(molecular_subtype))) %>%
    unique()
  }

# add back the remaining biospecimens and any without data, mark as TBC

mb_subtypes_all <- mb_rna_methyl_dups_rm %>%
  full_join(mb_biospecimens[,c("Kids_First_Participant_ID", "Kids_First_Biospecimen_ID", "match_id", "sample_id")]) %>%
  mutate(molecular_subtype = case_when(is.na(molecular_subtype) ~ "MB, To be classified",
                                       TRUE ~ molecular_subtype)) %>%
  select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, match_id, sample_id, molecular_subtype, molecular_subtype_methyl) %>%
  arrange(Kids_First_Participant_ID, match_id) %>%
  write_tsv(file.path(output_dir, results_file))

# how many tumor in each subgroup?
mb_subtypes_all %>%
  select(match_id, molecular_subtype) %>%
  unique() %>%
  dplyr::count(molecular_subtype)

# how many patients subtyped?
mb_subtypes_all %>%
  filter(molecular_subtype != "MB, To be classified") %>%
  pull(Kids_First_Participant_ID) %>%
  unique() %>%
  length()

# how many tumors subtyped?
mb_subtypes_all %>%
  filter(molecular_subtype != "MB, To be classified") %>%
  pull(match_id) %>%
  unique() %>%
  length()
