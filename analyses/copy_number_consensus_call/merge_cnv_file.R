library(tidyverse)

# set directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
cnv_gatk_dir <- file.path(root_dir, "analyses", "copy_number_consensus_call", "results")
cnv_manta_dir <- file.path(root_dir, "analyses", "copy_number_consensus_call_manta", "results")
output_file <- file.path(cnv_gatk_dir,  "cnv-consensus.seg.gz")

# read cnv files
cnv_gatk <- readr::read_tsv(file.path(cnv_gatk_dir, "cnv-consensus-freec-ckit-gatk.seg.gz"))
cnv_manta <- readr::read_tsv(file.path(cnv_manta_dir, "cnv-consensus-freec-ckit-manta.seg.gz"))

# merge two files together
merged <- rbind(cnv_gatk, cnv_manta) %>% 
  distinct() %>% 
  readr::write_tsv(output_file)
