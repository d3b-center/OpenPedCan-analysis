library(tidyverse)
library(openxlsx)

## set directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
input_dir <- file.path(root_dir, "data")
output_dir <- file.path(root_dir, "tables", "results")
mb_dir <- file.path(root_dir, "analyses", "molecular-subtyping-MB", "results")

## read file
hist <- read_tsv(file.path(input_dir, "histologies.tsv"))

## all molecular subtype ##
hist_sample <- hist %>% 
  filter(sample_type == "Tumor") %>%
  select(match_id, broad_histology, molecular_subtype) %>% 
  filter(!is.na(molecular_subtype)) %>% 
  distinct() %>% 
  group_by(broad_histology, molecular_subtype) %>% 
  tally() %>% 
  dplyr::rename("Tumors" = "n")
  
hist_patient <- hist %>% 
  filter(sample_type == "Tumor") %>%
  select(Kids_First_Participant_ID, broad_histology, molecular_subtype) %>% 
  filter(!is.na(molecular_subtype)) %>% 
  distinct() %>% 
  group_by(broad_histology, molecular_subtype) %>% 
  tally() %>% 
  dplyr::rename("Patients" = "n")

hist_combined <- hist_sample %>% 
  left_join(hist_patient) %>% 
  dplyr::rename("Broad Histologies" = "broad_histology", 
                "OpenPedCan Molecular Subtype" = "molecular_subtype")
hist_combined <- hist_combined %>% 
  ungroup() %>%
  add_row(`Broad Histologies` = "", 
          `OpenPedCan Molecular Subtype` = "Total", 
          Tumors = sum(hist_combined$Tumors), 
          Patients = sum(hist_combined$Patients))

## MB subtype 
MB_subtype <- read_tsv(file.path(mb_dir, "mb_shh_molecular_subtypes.tsv"))

## fianl table
final_table <- list(histologies_summary = hist_combined, 
                    MB_SHH_subtype = MB_subtype)
write.xlsx(final_table, 
           file.path(output_dir, "SuppTable3-Molecular-Subtype-Table.xlsx"))
