## subset maf file
library(tidyverse)

## set directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
data_dir <- file.path(root_dir, "data", "v13")
subset_dir <- file.path(root_dir, "analyses", "DMG_analysis", "subset")
result_dir <- file.path(root_dir, "analyses", "DMG_analysis", "results")

hist <- read_tsv(file.path(data_dir, "histologies.tsv"))
selected_sample <- hist %>% 
  filter(grepl(c("DMG"), molecular_subtype))

## subset genes of interests
gene_of_interests <- c("H3-3A", "H3C2", "H3C3", "H3C14", 
                       "EGFR", "TP53", "ATRX", "NF1")

tumor_only_maf <- data.table::fread(
  file.path(data_dir, "snv-mutect2-tumor-only-plus-hotspots.maf.tsv.gz"),
  data.table = FALSE) %>% 
  filter(Tumor_Sample_Barcode %in% selected_sample$Kids_First_Biospecimen_ID, 
         Hugo_Symbol %in% gene_of_interests)

# Add tumor only to consensus MAF
snv_consensus_hotspot_maf <- data.table::fread(
  file.path(data_dir, "snv-consensus-plus-hotspots.maf.tsv.gz"),
  data.table = FALSE) %>%
  filter(Tumor_Sample_Barcode %in% selected_sample$Kids_First_Biospecimen_ID, 
         Hugo_Symbol %in% gene_of_interests) 

tumor_only_maf$PUBMED <- as.character(tumor_only_maf$PUBMED)
tumor_only_maf$PHENO <- as.character(tumor_only_maf$PHENO)
tumor_only_maf$gnomad_3_1_1_AF_non_cancer <- as.character(tumor_only_maf$gnomad_3_1_1_AF_non_cancer)

snv_final <- snv_consensus_hotspot_maf %>%  
  dplyr::bind_rows(tumor_only_maf) 

write_tsv(snv_final, file.path(subset_dir, "snv_selected_genes.maf.tsv"))
