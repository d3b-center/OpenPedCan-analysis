library(GenomicFeatures)
library(tidyverse)
library(optparse)
options(readr.show_col_types = FALSE)

option_list <- list(
  make_option(c("--gtf_file"),
              type = "character", default = NULL,
              help = "gtf file"
  ),
  make_option(c("--output_file"),
              type = "character", default = NULL,
              help = "outputfile with given columns from gtf"
  ),
  make_option(c("--version"),
              type = "character", default = NULL,
              help = "version of the source gtf file"
  )
)

opt <- parse_args(OptionParser(option_list = option_list))

genes <- read_tsv(opt$gtf_file, col_names = F,comment = "#")[,c(1, 3, 4, 5,7, 9)]
colnames(genes) <- c("contig", "type", "start", "end", "strand","attributes")
genes <- genes[genes$type == "gene",]
genes$gene_symbol <- gsub(".*gene_name \"?([^;\"]+)\"?;.*", "\\1", genes$attributes)
genes$ensembl <- gsub(".*gene_id \"?([^;\"]+)\"?;.*", "\\1", genes$attributes)
genes$version <- opt$version


genes %>%
  select(gene_symbol,	ensembl, version) %>%
  # Discard the gene version information in order to get gene symbols and
  # cytoband mappings
  dplyr::mutate(ensembl = gsub("\\..*", "", ensembl))%>%
  write_tsv(opt$output_file)
