library(tidyverse)
library(reshape2)

## set directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
data_dir <- file.path(root_dir, "data", "v13")
subset_dir <- file.path(root_dir, "analyses", "DMG_analysis", "subset")
result_dir <- file.path(root_dir, "analyses", "DMG_analysis", "results")


## read histologies
hist <- read_tsv(file.path(data_dir, "histologies.tsv"))
selected_sample <- hist %>% 
  filter(grepl(c("DMG"), molecular_subtype))

##snv file
snv_annotate <- read_tsv(file.path(subset_dir, "snv_selected_genes_oncokb.maf.tsv"))
snv_annotate_short <- snv_annotate %>% 
  mutate(MUTATION_EFFECT = case_when(Hugo_Symbol == "EGFR" & 
                                       HGVSp_Short %in% c("p.A289V", "p.A289T") ~ 
                                       paste(MUTATION_EFFECT, "WHO mutation", sep = ";"), 
                                     TRUE ~ MUTATION_EFFECT)) %>%
  select(Tumor_Sample_Barcode, MUTATION_EFFECT, Hugo_Symbol)

## cn files
cn_df <- read_tsv(file.path(data_dir, "consensus_wgs_plus_cnvkit_wxs_plus_freec_tumor_only.tsv.gz"))
cn_filtered <- cn_df %>% 
  filter(biospecimen_id %in% selected_sample$Kids_First_Biospecimen_ID,
         gene_symbol == "EGFR") %>% 
  select(biospecimen_id, status, gene_symbol) %>%
  dplyr::rename("Tumor_Sample_Barcode" = "biospecimen_id", 
                "MUTATION_EFFECT" = "status", 
                "Hugo_Symbol" = "gene_symbol") %>%
  mutate(MUTATION_EFFECT = case_when(MUTATION_EFFECT == "amplification" ~ "amplification", 
                                     TRUE ~ "")) 
rm(cn_df)

## combined cnv with snv
snv_onco <- cn_filtered %>%
  bind_rows(snv_annotate_short) %>%
  left_join(hist %>% select(Kids_First_Biospecimen_ID, match_id), 
            by = c("Tumor_Sample_Barcode" = "Kids_First_Biospecimen_ID")) %>%
  select(match_id, MUTATION_EFFECT, Hugo_Symbol) %>%
  unique() %>%
  group_by(match_id, Hugo_Symbol) %>% 
  summarise(status = paste0(MUTATION_EFFECT, collapse = ";")) %>% 
  spread(Hugo_Symbol, status)

## RNA files
RNA <- read_rds(file.path(data_dir, "gene-expression-rsem-tpm-collapsed.rds"))
col_rna <- selected_sample %>% filter(experimental_strategy == "RNA-Seq") %>% select(Kids_First_Biospecimen_ID, match_id)

select_RNA <- RNA[rownames(RNA) %in% c("EZHIP", "EGFR"), col_rna %>% pull(Kids_First_Biospecimen_ID)]
select_RNA <- as.data.frame(scale(t(select_RNA)))
select_RNA$Kids_First_Biospecimen_ID <- rownames(select_RNA)

select_RNA <- select_RNA %>% 
  mutate(EGFR_exp = case_when(EGFR >=3 ~ "overexpression", 
                              TRUE ~ NA), 
         EZHIP_exp = case_when(EZHIP >=3 ~ "overexpression", 
                               TRUE ~ NA)) %>% 
  left_join(selected_sample %>% select(Kids_First_Biospecimen_ID, match_id)) %>% 
  select(match_id, EGFR_exp, EZHIP_exp) %>% 
  unique()

## gather all datas into one table
final_df <- selected_sample %>% 
  select(match_id, age_at_diagnosis_days, reported_gender, molecular_subtype, tumor_descriptor) %>%
  unique() %>%
  left_join(snv_onco) %>% 
  left_join(select_RNA) %>%
  mutate(reported_gender = case_when(reported_gender == "Not Reported" ~ "Unknown", TRUE ~ reported_gender)) %>% 
  write_tsv(file.path(result_dir, "df_for_oncoplot.tsv"))

