# Summarize methylation `Beta-values` and `M-values` to obtain a representative
# `median value` per CpG probe site for all samples from each cancer type 
# preprocessed from Illumina Infinium HumanMethylation450 BeadArrays. 
# It also annotates the CpG probe sites with the associated genes from the 
# evidence-based annotation of the human genome (hg19/GRCh37), GENCODE 
# version 19 (Ensembl 74), on which the array CpG site coordinates are based. 

# Eric Wafula for Pediatric OpenTargets
# 02/09/2022

# Load libraries
suppressWarnings(
  suppressPackageStartupMessages(library(rtracklayer))
)
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
options(dplyr.summarise.inform = FALSE)

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module and results directories
module_dir <- file.path(root_dir, "analyses", "methylation-analysis")
metadata_dir <- file.path(module_dir, "metadata")
results_dir <- file.path(module_dir, "results")

# Function to load, summarize, and reformat methylation values
summarize_meth_values <- function(meth_file) {
  # read UCSC Ensembl to RefSeq mapping file
  ensembl2refseq <- data.table::fread(
    file.path(metadata_dir, "UCSC_hg19-GRCh37_Ensembl2RefSeq.tsv"), 
    showProgress = FALSE) %>% 
    tibble::tibble() %>% 
    dplyr::rename(ensembl_id = "#hg19.knownToEnsembl.value",
                  gene_symbol = "hg19.kgXref.geneSymbol", 
                  accession = "hg19.kgXref.refseq")
  # read GENCODE v19 GTF file
  gtf <- file.path(metadata_dir, "gencode.v19.annotation.gtf.gz")
  ensembl2gene <- rtracklayer::import(con = gtf) %>% 
    as.data.frame() %>% 
    dplyr::tibble() %>%
    dplyr::select(transcript_id, gene_name) %>%
    dplyr::rename(ensembl_id = transcript_id, gene = gene_name) %>% 
    dplyr::mutate(ensembl_id = stringr::str_extract(ensembl_id, "ENST\\d+"))
  # get RefSeq to Ensembl GENECODE gene symbol mapping
  refseq2ensemblGene <- ensembl2gene %>% 
    left_join(ensembl2refseq, by = "ensembl_id") %>% 
    dplyr::select(gene, accession) %>% 
    dplyr::distinct()
  # extract cancer type from methlyation file name  
  cancer_types <- stringr::str_extract(
    stringr::str_extract(basename(meth_file), "\\w+"), "\\D+")
  # create table with median methylation median scores
  required_cols <- c("Probe", "Meth_Value", "Chromosome", "Position", 
                     "UCSC_RefGene_Name", "UCSC_RefGene_Accession")
  meth_table <- data.table::fread(meth_file, 
                                  select = required_cols, 
                                  showProgress = FALSE) %>% 
    tibble::tibble() %>% 
    dplyr::rename(probe = Probe, 
                  chromosome = Chromosome, 
                  position = Position,
                  name = UCSC_RefGene_Name, 
                  accession = UCSC_RefGene_Accession ) %>% 
    dplyr::group_by(probe, chromosome, position, name, accession) %>% 
    dplyr::summarise(beta = median(Meth_Value)) %>% 
    tidyr::separate_rows(name, accession, sep = ";", convert = FALSE) %>% 
    dplyr::distinct() %>% 
    dplyr::mutate(histology =
                    stringr::str_extract(cancer_types, "\\D+")) %>% 
    dplyr::inner_join(refseq2ensemblGene, by = "accession") %>% 
    dplyr::select(probe, chromosome, position, gene, beta, histology) %>% 
    dplyr::distinct() %>% 
  return(meth_table)
}

# Summarizing  methylation Beta-values for normal and all cancer types
message("====================================")
message(c("Summarizing methylation Beta-values"))
message("====================================\n")

# Normal beta-values samples
message("Summarizing Normal Beta-values...\n")
normal_meth_values <- summarize_meth_values(
  file.path(results_dir, "Normal-beta-values-methylation.tsv.gz"))

# NBL beta-values samples
message("Summarizing Neuroblastoma (NBL) Beta-values...\n")
nbl_meth_values <- summarize_meth_values(
  file.path(results_dir, "NBL-beta-values-methylation.tsv.gz"))

# OS beta-values samples
message("Summarizing Osteosarcoma (OS) Beta-values...\n")
os_meth_values <- summarize_meth_values(
  file.path(results_dir, "OS-beta-values-methylation.tsv.gz"))

# CCSK beta-values samples
message("Summarizing Clear Cell Sarcoma of the Kidney (CCSK) Beta-values...\n")
ccsk_meth_values <- summarize_meth_values(
  file.path(results_dir, "CCSK-beta-values-methylation.tsv.gz"))

# WT beta-values samples 
message("Summarizing Wilms Tumor (WT) Beta-values...\n")
wt_meth_values <- summarize_meth_values(
  file.path(results_dir, "WT-beta-values-methylation.tsv.gz"))

# AML beta-values samples 
message("Summarizing Acute Myeloid Leukemia (AML) Beta-values...\n")
aml_meth_values <- summarize_meth_values(
  file.path(results_dir, "AML450k-beta-values-methylation.tsv.gz"))

# merge summarized beta-values
message("Merging summarized Beta-values for normal and all cancer types ...\n")
meth_values <- rbind(normal_meth_values, nbl_meth_values, os_meth_values, 
                      ccsk_meth_values, wt_meth_values, aml_meth_values)
rm(normal_meth_values, nbl_meth_values, os_meth_values, 
      ccsk_meth_values, wt_meth_values, aml_meth_values)

# write summarized beta-values to file
message("Writing summarized Beta-values to median-beta-values-methylation.tsv file...\n")
meth_values %>% dplyr::arrange(chromosome, gene, probe) %>% 
  data.table::setDT() %>%
  data.table::fwrite(file.path(results_dir,
                               "median-beta-values-methylation.tsv.gz"), 
                     sep="\t", compress = "auto")
rm(meth_values)

# Summarizing  methylation M-values for normal and all cancer types
message("====================================")
message(c("Summarizing methylation M-values"))
message("====================================\n")

# Normal m-values samples
message("Summarizing Normal M-values...\n")
normal_meth_values <- summarize_meth_values(
  file.path(results_dir, "Normal-m-values-methylation.tsv.gz"))

# NBL m-values samples
message("Summarizing Neuroblastoma (NBL) M-values...\n")
nbl_meth_values <- summarize_meth_values(
  file.path(results_dir, "NBL-m-values-methylation.tsv.gz"))

# OS m-values samples
message("Summarizing Osteosarcoma (OS) M-values...\n")
os_meth_values <- summarize_meth_values(
  file.path(results_dir, "OS-m-values-methylation.tsv.gz"))

# CCSK m-values samples
message("Summarizing Clear Cell Sarcoma of the Kidney (CCSK) M-values...\n")
ccsk_meth_values <- summarize_meth_values(
  file.path(results_dir, "CCSK-m-values-methylation.tsv.gz"))

# WT m-values samples 
message("Summarizing Wilms Tumor (WT) M-values...\n")
wt_meth_values <- summarize_meth_values(
  file.path(results_dir, "WT-m-values-methylation.tsv.gz"))

# AML m-values samples 
message("Summarizing Acute Myeloid Leukemia (AML) M-values...\n")
aml_meth_values <- summarize_meth_values(
  file.path(results_dir, "AML450k-m-values-methylation.tsv.gz"))

# merge summarized m-values
message("Merging summarized M-values for normal and all cancer types ...\n")
meth_values <- rbind(normal_meth_values, nbl_meth_values, os_meth_values, 
                      ccsk_meth_values, wt_meth_values, aml_meth_values)
rm(normal_meth_values, nbl_meth_values, os_meth_values, 
   ccsk_meth_values, wt_meth_values, aml_meth_values)

# write summarized m-values to file
message("Writing summarized M-values to median-m-values-methylation.tsv file...\n")
meth_values %>% dplyr::arrange(chromosome, gene, probe) %>%
  data.table::setDT() %>%
  data.table::fwrite(file.path(results_dir,
                               "median-m-values-methylation.tsv.gz"),
                     sep="\t", compress = "auto")
rm(meth_values)

message("Analysis Done..\n")


