library(tidyverse)

## set directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

## read files
histo <- readr::read_tsv(file.path(root_dir, "data", "histologies-base.tsv"))
cnv <- readr::read_tsv(file.path(root_dir, "data", "cnv-gatk.seg.gz")) %>% 
  pull("BS_ID") %>% 
  unique()

WGS_list <- histo %>%
  filter(experimental_strategy == "WGS" & !is.na(pathology_diagnosis)) %>% 
  pull("Kids_First_Biospecimen_ID") %>% 
  unique() %>% 
  setdiff(., cnv)

histo_WGS <- histo %>%
  filter(Kids_First_Biospecimen_ID %in% WGS_list) %>% 
  readr::write_tsv(file.path(root_dir, "copy_number_consensus_call_manta", "missing_wgs.tsv"))
