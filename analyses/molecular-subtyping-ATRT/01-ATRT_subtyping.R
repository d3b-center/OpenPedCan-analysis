#This script assigns ATRT into three known subtypes using methylation result.
#Subtypiong esults is saved as ATRT-molecular-subtypes.tsv

# Set up library
library(tidyverse)

# Detect the ".git" folder -- this will in the project root directory.
# Use this as the root directory to ensure proper sourcing of functions no
# matter where this is called from
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to result
results_dir <-
  file.path(root_dir, "analyses", "molecular-subtyping-ATRT", "results")

# Directory of json file for subseting
atrt_subset_file <- file.path(root_dir, "analyses", "molecular-subtyping-ATRT", "atrt-subset", "ATRT_subtyping_path_dx_strings.json")

# Read in histologies
histo <- 
  readr::read_tsv(file.path(root_dir, "data", "histologies-base.tsv"), guess_max = 100000)

# Read json file
path_dx_list_atrt <- jsonlite::fromJSON(atrt_subset_file)
  
# Filter histo, 
# select all ATRT biospecimens from PBTA and/DGD
atrt_df <- histo %>%
  dplyr::filter(cohort %in% c("PBTA", "Kentucky", "DGD")) %>%
  dplyr::filter(pathology_diagnosis %in% path_dx_list_atrt$exact_path_dx) %>%
  # create match id
  mutate(id = paste(sample_id, composition, sep = "_"))

# Create a dataframe with sample_id and matched biospecimens id for RNA-Seq, WGS and methylation
atrt_df_methyl <- atrt_df %>% 
  filter(experimental_strategy == "Methylation",
         dkfz_v12_methylation_subclass_score >= 0.8,
         grepl("ATRT_", dkfz_v12_methylation_subclass)) %>%
  select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, sample_id, composition, 
         dkfz_v12_methylation_subclass, dkfz_v12_methylation_subclass_score) %>%
  # mutate ATRT subtypes from methyl so they are in the format needed later
  mutate(molecular_subtype = case_when(dkfz_v12_methylation_subclass == "ATRT_MYC" ~ "ATRT, MYC",
                                                   dkfz_v12_methylation_subclass == "ATRT_SHH" ~ "ATRT, SHH",
                                                   dkfz_v12_methylation_subclass == "ATRT_TYR" ~ "ATRT, TYR",
                                                   TRUE ~ dkfz_v12_methylation_subclass),
         # create match id
         id = paste(sample_id, composition, sep = "_")) 

methyl_no_subtype <- atrt_df %>% 
  filter(experimental_strategy == "Methylation",
         !id %in% atrt_df_methyl$id) %>% 
  select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, sample_id, composition, 
         dkfz_v12_methylation_subclass, dkfz_v12_methylation_subclass_score) %>%
  mutate(molecular_subtype = "ATRT, To be classified", 
         id = paste(sample_id, composition, sep = "_")) 


# make a methyl map
methyl_map <- atrt_df_methyl %>%
  bind_rows(methyl_no_subtype) %>%
  select(id, molecular_subtype) %>%
  unique() %>%
  mutate(molecular_subtype_methyl = molecular_subtype)

# any dups? no
length(unique(methyl_map$id)) == length(methyl_map$id)


# for the samples, whose cns_methlation_subclass_score >= 0.8 and dkfz_v12_methylation_subclass is one of the three types in ATRT_subtype_list, their molecular subtype are same as dkfz_v12_methylation_subclass
# for the samples without methylation sequencing, their molecular subtype are "ATRT, To be classified."
# For the samples fit all the other situations, their molecular subtype are "ATRT, To be classified."
atrt_subtype_final <- atrt_df %>% 
  select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, sample_id, composition, id) %>%
  left_join(methyl_map) %>%
  mutate(molecular_subtype = case_when(is.na(molecular_subtype) ~ "ATRT, To be classified",
                                       TRUE ~ molecular_subtype)) %>%
  # write result
  readr::write_tsv(file.path(results_dir, "ATRT-molecular-subtypes.tsv"))


# how many tumors subtyped?
tumors_subtyped <- atrt_subtype_final %>%
  select(id, molecular_subtype) %>%
  unique() %>%
  count(molecular_subtype)

print(tumors_subtyped)
