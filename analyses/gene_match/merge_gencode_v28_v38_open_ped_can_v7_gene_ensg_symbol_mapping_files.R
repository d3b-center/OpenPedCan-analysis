library(tidyverse)

v28_eh_df <- read_tsv('results/ensembl_gene_symbol_gtf_genode_v28.tsv')
v38_eh_df <- read_tsv('results/ensembl_gene_symbol_gtf_genode_v38.tsv')

open_ped_can_v7_eh_df <- read_tsv('input/open_ped_can_v7_ensg-hugo-rmtl-mapping.tsv') %>%
  select(gene_symbol, ensg_id) %>%
  rename(ensembl = ensg_id)

merged_eh_df <- distinct(bind_rows(v28_eh_df, v38_eh_df, open_ped_can_v7_eh_df))

write_tsv(merged_eh_df, 'results/ensembl_gene_symbol_gtf_genode_v28_v38_open_ped_can_v7_merged.tsv')
