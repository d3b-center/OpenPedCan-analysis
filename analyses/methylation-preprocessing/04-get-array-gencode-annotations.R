# Parse GENCODE annotation of the human genome (GRCh37), version 19 (Ensembl 74),
# and associated feature coordinates for genes in the Illumina Infinium 
# HumanMethylation450 BeadArrays annotation design to use for plotting 
# comparative methylation profiles with GViz R package in association with any 
# one of the two results tables of representative median CpG probe sites 
# methylation values.

# Eric Wafula for Pediatric OpenTargets
# 02/09/2022

message("=========================================================================")
message(c("Create Illumina Infinium HumanMethylation450 BeadArrays GENCODE Table"))
message("=========================================================================\n")

# Load libraries
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))
suppressWarnings(
  suppressPackageStartupMessages(library(rtracklayer))
)


# Magrittr pipe
`%>%` <- dplyr::`%>%`

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module, and metadata directories
module_dir <- file.path(root_dir, "analyses", "methylation-analysis")
results_dir <- file.path(module_dir, "results")
metadata_dir <- file.path(module_dir, "metadata")

# get array gene symbols
message("Get array-specific gene annotations symbols...\n")
meth_table <- file.path(results_dir, "median-beta-values-methylation.tsv.gz")
gene_symbols <- data.table::fread(meth_table, select = "gene", 
                                showProgress = FALSE) %>% 
  dplyr::distinct() %>% 
  dplyr::pull(gene) 
  
# Parse gencode gtf file
message("Parsing GENCODE GTF for array-specifc annotations...\n")
gtf <- file.path(metadata_dir, "gencode.v19.annotation.gtf.gz")
gencode_table <- rtracklayer::import(con = gtf) %>% 
  as.data.frame() %>% 
  dplyr::tibble() %>%
  dplyr::select(seqnames, start, end, width, strand, type, gene_type, gene_id, 
                transcript_id, exon_id, gene_name) %>% 
  dplyr::rename(chromosome = seqnames, feature = gene_type, gene = gene_id,
                transcript = transcript_id, exon = exon_id, 
                symbol = gene_name) %>% 
  dplyr::filter(symbol %in% gene_symbols) %>% 
  dplyr::mutate(gene = stringr::str_extract(gene, "ENSG\\d+"),
                transcript = stringr::str_extract(transcript, "ENST\\d+"),
                exon = stringr::str_extract(exon, "ENSE\\d+")) %>% 
  dplyr::arrange()

# write array gencode annotations to file
message("Writing array GENCODE annotations to methylation-array-gencode.annotations.tsv.gz file...\n")
gencode_table %>% data.table::setDT() %>%
data.table::fwrite(file.path(results_dir,
                               "methylation-array-gencode.annotations.tsv.gz"),
                     sep="\t", compress = "auto")

message("Analysis Done..\n")
  

