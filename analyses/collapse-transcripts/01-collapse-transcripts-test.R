# Author: Jo Lynne Rokita, Adapted from Komal S. Rathi
# Date: 2022
# Function: 
# 1. summarize RNA-seq transcripts to ENST x Sample matrix
# 2. tabulate corresponding transcript annotations

# Example run: 
# Rscript analyses/collapse-rnaseq/01-collapse-transcripts.R \
# -i data/rna-isoform-expression-rsem-tpm.rds \
# -g data/gencode.v27.primary_assembly.annotation.gtf.gz \
# -m analyses/collapse-transcripts/rna-isoform-expression-rsem-tpm-collapsed.rds \

suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(rtracklayer))

option_list <- list(
  make_option(c("-i", "--inputmat"), type = "character",
              help = "Input matrix of merged RSEM isoform files (.RDS)"),
  make_option(c("-g", "--inputgtf"), type  = "character",
              help = "Input gtf file (.gtf)"),
  make_option(c("-m", "--outputmat"), type = "character",
              help = "Output matrix (.RDS)"),
  make_option(c("-t", "--dupstable"), type = "character",
              help = "Output gene annotation table (.RDS)")
)

# parse the parameters
opt <- parse_args(OptionParser(option_list = option_list))
input.mat <- opt$inputmat
input.gtf <- opt$inputgtf
output.mat <- opt$outputmat
dups.tab <- opt$dupstable

print("Generating input matrix and drops table...!")
print("Read merged RSEM isoform data")
expr <- readRDS(input.mat)

# read gencode (v27 for the paper) to get gene id-gene symbo-gene type annotation
# Remove dups/NAs
gtf <- rtracklayer::import(input.gtf)
#gtf <- rtracklayer::import("OpenPedCan-analysis/data/gencode.v27.primary_assembly.annotation.gtf.gz")
gtf <- gtf %>% 
  as.data.frame() %>%
  filter(!is.na(transcript_id)) %>%
  select(transcript_id, gene_id, gene_name, gene_type) %>%
  mutate(gene_id = str_replace_all(gene_id, "_PAR_Y", "")) %>%
  unique()

# identify non-unique transcripts
dups <- gtf %>% 
  select(transcript_id, gene_name) %>%
  unique() %>% 
  group_by(gene_name) %>%
  mutate(transcript.ct = n()) %>%
  filter(transcript.ct > 1) %>%
  unique()
gtf$ensembl_id <- ifelse(gtf$transcript_id %in% dups$transcript_id, "Multiple", "Unique")

# split gene id and symbol
expr <- expr %>% 
  mutate(transcript_id = str_replace(transcript_id, "_PAR_Y_", "_"))  %>%
  separate(transcript_id, c("transcript_id", "gene_symbol"), sep = "\\_", extra = "merge") %>%
  unique() 

# remove all genes with no expression
expr <- expr[which(rowSums(expr[,3:ncol(expr)]) > 0),] 
gtf$expressed <- ifelse(gtf$transcript_id %in% expr$transcript_id, "Yes", "No")

# collapse to matrix of ENST x Sample identifiers
# take mean per row and use the max value for duplicated gene symbols
expr.collapsed <- expr %>% 
  mutate(means = rowMeans(select(.,-transcript_id, -gene_symbol))) %>% # take rowMeans
  arrange(desc(means)) %>% # arrange decreasing by means
  distinct(gene_symbol, .keep_all = TRUE) %>% # keep the ones with greatest mean value. If ties occur, keep the first occurencce
  select(-means) %>%
  unique() %>%
  remove_rownames() 
gtf$keep <- ifelse(gtf$transcript_id %in% expr.collapsed$transcript_id, "Yes", "No")

# correlation analysis
# for multi-mapped genes, calculate average correlation of selected gene id with discarded gene ids
multi.mapped <- gtf %>% filter(ensembl_id == "Multiple" & expressed == "Yes")
for.corr <- merge(expr, multi.mapped[,c("gene_id", "transcript_id", "keep")], by.x = "transcript_id")

# function to calculate avg. correlation across kept gene vs discarded genes
calc.mean.corr <- function(x){
  gene.id <- x[which(x$keep == "Yes"),"transcript_id"]
  x1 <- x %>% 
    filter(keep == "Yes") %>%
    select(-c(gene_id, gene_symbol, transcript_id, keep)) %>%
    as.numeric()
  x2 <- x %>% 
    filter(keep == "No") %>%
    select(-c(gene_id, gene_symbol, transcript_id, keep))
  
  # correlation of kept id with discarded ids
  cor <- mean(apply(x2, 1, FUN = function(y) cor(x1, y)))
  cor <- round(cor, digits = 2)
  df <- data.frame(avg.cor = cor, transcript_id = gene.id)
  return(df)
}
for.corr <- for.corr %>%
  split(.$transcript_id) %>%
  map_dfr(~ calc.mean.corr(.), .id = 'transcript_id')

# add average correlations to drops table
gtf <-  merge(gtf, for.corr, by = c('transcript_id', 'gene_name'), by.y = c('transcript_id', 'gene_symbol'), all.x = TRUE)

# matrix of HUGO symbols x Sample identifiers
expr.input <- expr.collapsed %>% 
  column_to_rownames("gene_symbol") %>%
  select(-c(transcript_id)) 
print(dim(expr.input)) # Add N

# final geneid-symbol-biotype annotation file
print("Generating duplicates table...")
saveRDS(object = gtf, file = dups.tab)

# save matrix
print("Saving collapsed matrix...")
saveRDS(object = expr.input, file = output.mat)
print("Done!!")
