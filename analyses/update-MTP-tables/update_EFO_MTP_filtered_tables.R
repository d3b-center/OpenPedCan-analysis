#curl -O https://s3.amazonaws.com/d3b-openaccess-us-east-1-prd-pbta/open-targets/mtp-tables/filtered-for-gencode-v39-and-OT/gene-level-snv-consensus-annotated-mut-freq.tsv.gz


# Invoke libraries
library(tidyverse)
library(jsonlite)


# Read files
file_path <- getwd()

fusion_freq <- read_tsv("putative-oncogene-fusion-freq.tsv.gz")
fused_gene_freq <- read_tsv("putative-oncogene-fused-gene-freq.tsv.gz")
var_snv_freq <- read_tsv("variant-level-snv-consensus-annotated-mut-freq.tsv.gz")
gene_snv_freq <- read_tsv("gene-level-snv-consensus-annotated-mut-freq.tsv.gz")
gene_cnv_freq <- read_tsv("gene-level-cnv-consensus-annotated-mut-freq.tsv.gz")
tpm_gene_zscore <- read_tsv("long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz")
tpm_group_zscore <- read_tsv("long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz")



# Replace EFO code for Wilms tumor
fusion_freq <- fusion_freq %>%
  mutate(diseaseFromSourceMappedId = replace(diseaseFromSourceMappedId, diseaseFromSourceMappedId == "MONDO_0006058", "MONDO_0019004"))

fused_gene_freq <- fused_gene_freq %>%
  mutate(diseaseFromSourceMappedId = replace(diseaseFromSourceMappedId, diseaseFromSourceMappedId == "MONDO_0006058", "MONDO_0019004"))

var_snv_freq <- var_snv_freq %>%
  mutate(diseaseFromSourceMappedId = replace(diseaseFromSourceMappedId, diseaseFromSourceMappedId == "MONDO_0006058", "MONDO_0019004"))

gene_snv_freq <- gene_snv_freq %>%
  mutate(diseaseFromSourceMappedId = replace(diseaseFromSourceMappedId, diseaseFromSourceMappedId == "MONDO_0006058", "MONDO_0019004"))

gene_cnv_freq <- gene_cnv_freq %>%
  mutate(diseaseFromSourceMappedId = replace(diseaseFromSourceMappedId, diseaseFromSourceMappedId == "MONDO_0006058", "MONDO_0019004"))

tpm_gene_zscore <- tpm_gene_zscore %>%
  mutate(MONDO = replace(MONDO, MONDO == "MONDO_0006058", "MONDO_0019004"))

tpm_group_zscore <- tpm_group_zscore %>%
  mutate(MONDO = replace(MONDO, MONDO == "MONDO_0006058", "MONDO_0019004"))


# Validate if the replaced code value is not for Wilms tumor

stopifnot(identical("Wilms tumor", fusion_freq %>% filter(diseaseFromSourceMappedId=="MONDO_0019004") %>% pull(Disease) %>% unique()))
stopifnot(identical("Wilms tumor", fused_gene_freq %>% filter(diseaseFromSourceMappedId=="MONDO_0019004") %>% pull(Disease) %>% unique()))
stopifnot(identical("Wilms tumor", var_snv_freq %>% filter(diseaseFromSourceMappedId=="MONDO_0019004") %>% pull(Disease) %>% unique()))
stopifnot(identical("Wilms tumor", gene_snv_freq %>% filter(diseaseFromSourceMappedId=="MONDO_0019004") %>% pull(Disease) %>% unique()))
stopifnot(identical("Wilms tumor", gene_cnv_freq %>% filter(diseaseFromSourceMappedId=="MONDO_0019004") %>% pull(Disease) %>% unique()))
stopifnot(identical("Wilms tumor", tpm_gene_zscore %>% filter(MONDO=="MONDO_0019004") %>% pull(Disease) %>% unique()))
stopifnot(identical("Wilms tumor", tpm_group_zscore %>% filter(MONDO=="MONDO_0019004") %>% pull(Disease) %>% unique()))


# Write tables to tsv and json files in local directory

write_tsv(
  fusion_freq,
  file.path(file_path, 'putative-oncogene-fusion-freq.tsv'))

jsonlite::write_json(
  fusion_freq,
  file.path(file_path, 'putative-oncogene-fusion-freq.json'))




write_tsv(
  fused_gene_freq,
  file.path(file_path, 'putative-oncogene-fused-gene-freq.tsv'))

jsonlite::write_json(
  fused_gene_freq,
  file.path(file_path, 'putative-oncogene-fused-gene-freq.json'))




write_tsv(
  var_snv_freq,
  file.path(file_path, 'variant-level-snv-consensus-annotated-mut-freq.tsv'))

jsonlite::write_json(
  var_snv_freq,
  file.path(file_path, 'variant-level-snv-consensus-annotated-mut-freq.json'))




write_tsv(
  gene_snv_freq,
  file.path(file_path, 'gene-level-snv-consensus-annotated-mut-freq.tsv'))

jsonlite::write_json(
  gene_snv_freq,
  file.path(file_path, 'gene-level-snv-consensus-annotated-mut-freq.json'))




write_tsv(
  gene_cnv_freq,
  file.path(file_path, 'gene-level-cnv-consensus-annotated-mut-freq.tsv'))

jsonlite::write_json(
  gene_cnv_freq,
  file.path(file_path, 'gene-level-cnv-consensus-annotated-mut-freq.json'))




write_tsv(
  tpm_gene_zscore,
  file.path(file_path, 'long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv'))

jsonlite::write_json(
  tpm_gene_zscore,
  file.path(file_path, 'long_n_tpm_mean_sd_quantile_gene_wise_zscore.json'))




write_tsv(
  tpm_group_zscore,
  file.path(file_path, 'long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv'))


jsonlite::write_json(
  tpm_group_zscore,
  file.path(file_path, 'long_n_tpm_mean_sd_quantile_group_wise_zscore.json'))


message('Done reading downloaded files, replacing EFO code, generating TSV and JSON files.')
