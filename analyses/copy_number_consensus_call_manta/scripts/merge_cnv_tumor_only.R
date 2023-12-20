library(tidyverse)

root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
data_dir <- file.path(root_dir, "data")

cnv_controlfreec <- read_tsv(file.path(data_dir, "cnv-controlfreec.tsv.gz"))
cnv_tumor_only <- read_tsv(file.path(data_dir, "cnv-controlfreec-tumor-only.tsv.gz"))

cnv_merged <- cnv_tumor_only %>% 
  bind_rows(cnv_controlfreec) %>% 
  write_tsv(file.path(root_dir, "scratch", "cnv-controlfreec-merged.tsv.gz"))
