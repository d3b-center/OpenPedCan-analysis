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
mb_results <- readRDS(file.path(output_dir, "mb-classified.rds"))$medulloPackage %>%
  dplyr::rename(Kids_First_Biospecimen_ID = sample,
                molecular_subtype = best.fit) %>%
  # format subtype result
  mutate(molecular_subtype = paste0("MB, ", molecular_subtype)) %>%
  select(Kids_First_Biospecimen_ID, molecular_subtype) %>%
  # pull in sample ID and composition
  left_join(mb_biospecimens[,c("Kids_First_Participant_ID", "Kids_First_Biospecimen_ID", "sample_id", "composition", "tumor_descriptor", "match_id")]) %>%
  mutate(id = paste(sample_id, composition, sep = "_")) %>%
  #rename RNA bs_id to enable joining of other bs_ids
  dplyr::rename(Kids_First_Biospecimen_ID_RNA = Kids_First_Biospecimen_ID)

# are there discrepancies? yes
rna_map <- mb_results %>%
  select(sample_id, composition, tumor_descriptor, molecular_subtype, match_id) %>%
  unique()

# we will add methyl subtypes in the absence of RNA-Seq classification or in the case of discrepant classifier results
methyl_bs_with_mb_subtypes <- mb_biospecimens %>%
  filter(str_detect(str_to_lower(pathology_diagnosis), path_dx_list$include_free_text), 
         experimental_strategy == "Methylation",
         (grepl("MB_", dkfz_v12_methylation_subclass) & dkfz_v12_methylation_subclass_score >= 0.8)) %>%
  # reformat classifier result per https://www.molecularneuropathology.org/mnp/classifiers/11
  mutate(molecular_subtype = case_when(grepl("MB_SHH", dkfz_v12_methylation_subclass) ~ "MB, SHH",
                                       dkfz_v12_methylation_subclass %in% c("MB_G34_I", "MB_G34_II", "MB_G34_III", "MB_G34_IV") ~ "MB, Group3",
                                       dkfz_v12_methylation_subclass %in% c("MB_G34_V", "MB_G34_VI", "MB_G34_VII", "MB_G34_VIII") ~ "MB, Group4",
                                       dkfz_v12_methylation_subclass == "MB_WNT" ~ "MB, WNT",
                                       dkfz_v12_methylation_subclass == "MB_MYO" ~ "MB, MYO")) %>%
  #dplyr::rename(Kids_First_Biospecimen_ID_methyl = Kids_First_Biospecimen_ID) %>%
  dplyr::select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, sample_id, composition, tumor_descriptor, molecular_subtype, match_id) 

# assign remaining methyl sample without the subtype of interests as NA

methyl_no_subtype <- mb_biospecimens %>%
  filter(str_detect(str_to_lower(pathology_diagnosis), paste(path_dx_list$include_free_text)), 
         experimental_strategy == "Methylation",
         !Kids_First_Biospecimen_ID %in% methyl_bs_with_mb_subtypes$Kids_First_Biospecimen_ID) %>% 
  mutate(molecular_subtype = NA_character_) %>% 
  mutate(id = paste(sample_id, composition, sep = "_")) %>%
  dplyr::select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, sample_id, composition, tumor_descriptor, molecular_subtype, match_id) 

methyl_bs_with_mb_subtypes <- methyl_bs_with_mb_subtypes %>% 
  rbind(methyl_no_subtype) %>% 
  distinct()

# are there any methylation discrepancies? no, OK we can use these to replace discrepancies in RNA-Seq
methyl_subtype_map <- methyl_bs_with_mb_subtypes %>%
  select(sample_id, composition, tumor_descriptor, molecular_subtype, match_id) %>%
  unique()

all.equal(length(unique(methyl_subtype_map$match_id)), nrow(methyl_subtype_map))


# 1 discrepant subtype pair from RNA results, let's fix it and set up to auto fix later
dups <- rna_map %>%
  filter(duplicated(.[["match_id"]])) 

if (nrow(dups) > 0) {
  mb_results <- mb_results %>%
  mutate(molecular_subtype = case_when(match_id %in% dups$match_id ~ NA_character_,
                                       TRUE ~ as.character(molecular_subtype)))
  tmp_df <- methyl_subtype_map %>%
    filter(match_id %in% dups$match_id)
    
  mb_results <- mb_results %>%
    left_join(tmp_df, by = c("match_id")) %>%
    mutate(Values=coalesce(molecular_subtype.x,molecular_subtype.y)) %>%
    select(-molecular_subtype.x,-molecular_subtype.y) %>%
    dplyr::rename(molecular_subtype = Values) %>%
    unique()
    
  }

# now add methylation results and associated samples if no rnaseq
methyl_bs_with_mb_subtypes_norna <- methyl_bs_with_mb_subtypes %>%
  filter(!match_id %in% mb_results$match_id) %>%
  dplyr::select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, sample_id, composition, tumor_descriptor, molecular_subtype, match_id) 

# these results will be the basis for all other bs_ids
base_results_map <- mb_results %>%
  bind_rows(methyl_bs_with_mb_subtypes_norna) %>%
  select(molecular_subtype, match_id) %>%
  unique()


# subset clinical for non rna-seq specimens
mb_biospecimens_subtyped <- mb_biospecimens %>%
  select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, sample_id, composition, tumor_descriptor, match_id) %>%
  left_join(base_results_map, by = "match_id") %>%
  #make all NA To be classified
  dplyr::mutate(molecular_subtype = case_when(is.na(molecular_subtype) ~ "MB, To be classified",
                                              TRUE ~ molecular_subtype)) %>%
  arrange(sample_id)

# how many tumor in each subgroup?
mb_biospecimens_subtyped %>%
  select(match_id, molecular_subtype) %>%
  unique() %>%
  dplyr::count(molecular_subtype)

# how many patients subtyped?
mb_biospecimens_subtyped %>%
  filter(molecular_subtype != "MB, To be classified") %>%
  pull(Kids_First_Participant_ID) %>%
  unique() %>%
  length()

# how many tumors subtyped?
mb_biospecimens_subtyped %>%
  filter(molecular_subtype != "MB, To be classified") %>%
  pull(match_id) %>%
  unique() %>%
  length()

### check accuracy of medulloPackage with methylation ------------------
methyl_subtype_map_short <- methyl_subtype_map %>%
  dplyr::rename(molecular_subtype_methyl = molecular_subtype) %>%
  select(match_id, molecular_subtype_methyl)

# add methyl subtype to the final subtype file
mb_biospecimens_subtyped_plus_methyl <- mb_biospecimens_subtyped %>%
  left_join(methyl_subtype_map_short) %>%
  arrange(sample_id) #%>%
  # let's write this out as the final file
  #write_tsv(file.path(output_dir, results_file))

# check accuracy
mb_biospecimens_subtyped_plus_methyl_subset <- mb_biospecimens_subtyped_plus_methyl %>%
  filter(!is.na(molecular_subtype_methyl),
         # remove methyl only samples
         !match_id %in% methyl_bs_with_mb_subtypes_norna$match_id) %>%
  select(match_id, molecular_subtype, molecular_subtype_methyl) %>%
  unique() %>%
  mutate(match = ifelse(molecular_subtype == molecular_subtype_methyl, "true", "false"))

n_match <- mb_biospecimens_subtyped_plus_methyl_subset %>%
  filter(match == "true") %>%
 nrow() 
print(paste0(n_match, " matches"))

n_no_match <- mb_biospecimens_subtyped_plus_methyl_subset %>%
  filter(match == "false") %>%
  nrow() 
print(paste0(n_no_match, " non-matches"))

Accuracy = paste0(round(n_match/sum(n_match+n_no_match)*100, 2), '%')
Accuracy
