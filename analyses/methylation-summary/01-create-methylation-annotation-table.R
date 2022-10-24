# Create combined probe annotations for preprocessed methylation arrays using 
# GENCODE version 38 (Ensembl 104) gene symbols

# Eric Wafula for Pediatric OpenTargets
# 03/18/2022

# Load libraries
suppressWarnings(
  suppressPackageStartupMessages(library(rtracklayer))
)
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module and results directories
data_dir <- file.path(root_dir, "data")
module_dir <- file.path(root_dir, "analyses", "methylation-summary")
input_dir <- file.path(module_dir, "input")
results_dir <- file.path(module_dir, "results")

# Create results directory if it doesn't exist
if (!dir.exists(results_dir)) {
  dir.create(results_dir)
}

# Function to parse preprocessed methylation results and annotate array
# probes with GENCODE gene symbols and  Ensembl IDs
annotate_array_probes <- function(meth_file) {
  # read UCSC Ensembl to RefSeq mapping file
  ensembl2refseq <- data.table::fread(
    file.path(input_dir, "UCSC_hg19-GRCh37_Ensembl2RefSeq.tsv"), 
    showProgress = FALSE) %>% 
    tibble::tibble() %>% 
    dplyr::rename(transcript_id = "#hg19.knownToEnsembl.value",
                  refseq_id = "hg19.kgXref.refseq")
  # read GENCODE GTF file
  gtf <- file.path(data_dir, "gencode.v38.primary_assembly.annotation.gtf.gz")
  ensembl2gene <- rtracklayer::import(con = gtf) %>% 
    as.data.frame() %>% 
    dplyr::tibble() %>%
    dplyr::select(gene_id, transcript_id, gene_name) %>%
    dplyr::rename(targetFromSourceId = gene_id, Gene_symbol = gene_name) %>% 
    dplyr::mutate(transcript_id = stringr::str_extract(transcript_id, "ENST\\d+"),
                  targetFromSourceId = stringr::str_extract(targetFromSourceId, "ENSG\\d+"))
  # get RefSeq to Ensembl GENECODE gene symbol mapping
  refseq2ensemblGene <- ensembl2gene %>% 
    left_join(ensembl2refseq, by = "transcript_id") %>% 
    dplyr::select(Gene_symbol, targetFromSourceId, refseq_id) %>% 
    dplyr::distinct()
  # Annotate methylation array probes
  required_cols <- c("Probe","Chromosome", "Position", "UCSC_RefGene_Accession")
  probe_annotations <- data.table::fread(meth_file, 
                                  select = required_cols, 
                                  showProgress = FALSE) %>% 
    tibble::tibble() %>% 
    dplyr::rename(Probe_ID = Probe, Location = Position, 
                  refseq_id = UCSC_RefGene_Accession) %>% 
    dplyr::distinct() %>% 
    tidyr::separate_rows(refseq_id, sep = ";", convert = FALSE) %>% 
    dplyr::distinct() %>% 
    dplyr::inner_join(refseq2ensemblGene, by = "refseq_id") %>% 
    dplyr::select(Probe_ID, Chromosome, Location, Gene_symbol, 
                  targetFromSourceId) %>% 
    dplyr::distinct() %>% 
  return(probe-annotations)
}

# Annotate array probes for each histology with GENCODE gene symbols and Ensembl
# IDs using preprocessed methylation Beta-values results
message("===========================================================")
message("Creating merged annotations for methylation array probes")
message("===========================================================\n")

# AML beta-values samples 
message("Annotating array probes in TARGET samples...\n")
target_annotations <- annotate_array_probes(
  file.path(data_dir, "TARGET-beta-values-methylation.tsv.gz"))

# CBTN beta-values samples 
message("Annotating array probes in CBTN samples...\n")
cbtn_annotations <- annotate_array_probes(
  file.path(data_dir, "CBTN-beta-values-methylation.tsv.gz"))

# merge array probe annotations
message("Merging array probes annotations for normal and all cancer types ...\n")
probe_annotations <- rbind(target_annotations, cbtn_annotations)
rm(target_annotations, cbtn_annotations)
probe_annotations <- probe_annotations %>% dplyr::distinct()

# write merged beta-values to file
message("Writing merged array probes annotations to methyl-probe-annotations.tsv file...\n")
probe_annotations %>% data.table::setDT() %>%
  data.table::fwrite(file.path(results_dir,
                               "methyl-probe-annotations.tsv.gz"), 
                     sep="\t", compress = "auto")

message("Analysis Done..\n")

