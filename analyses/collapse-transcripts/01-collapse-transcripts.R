# Author: 
# Date: 
# Function: 
# Collapses all RSEM transcripts into an RDS object

# Example run



# Load libraries
suppressPackageStartupMessages({
  library(optparse)
  library(data.table)
  library(dplyr)
  library(tidyverse)
  library(reshape2)
})


# Create options
option_list <- list(
  make_option(c("-i", "--isoform_input"), type = "character",
              help = "Input file for merged RSEM isoform TPM"),
  make_option(c("-o", "--isoform_output"), type = "character",
              default = "comparison-results",
              help = "Output RDS file for RSEM isoform TPM expression table")
)

# parse the parameters
opt <- parse_args(OptionParser(option_list = option_list))

isoform_input <- opt$isoform_input
isoform_collapsed_output <- opt$isoform_output


# Detect the ".git" folder -- this will in the project root directory.
# Use this as the root directory to ensure proper sourcing of functions no
# matter where this is called from
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
analysis_dir <- file.path(root_dir, "analyses")

# Create output directory if does not exist
outdir <- file.path(analysis_dir, "collapse-transcripts", "results")
if (!dir.exists(outdir)) {
  dir.create(outdir, recursive = TRUE)
}

# Set up input/output files
isoform_input <- file.path(root_dir, "data", "rna-isoform-expression-rsem-tpm.rds")
isoform_collapsed_output <- file.path(outdir, "rna-isoform-expression-rsem-tpm_collapsed.rds")

# Read in isoform file
isoforms <- readRDS(isoform_input)

# split gene id and symbol
isoforms <- isoforms %>% 
  mutate(transcript_id = str_replace(transcript_id, "_PAR_Y_", "_"))  %>%
  separate(transcript_id, c("transcript_id", "gene_symbol"), sep = "\\_", extra = "merge") %>%
  unique()

iso_ids_split[1:5,1:5]

# remove all genes with no expression
isoforms <- isoforms[which(rowSums(isoforms[,3:ncol(isoforms)]) > 0),] 

# collapse to matrix of ENST x Sample identifiers
# take mean per row and use the max value for duplicated ENST
iso.collapsed <- isoforms %>% 
  mutate(means = rowMeans(select(.,-transcript_id, -gene_symbol))) %>% # take rowMeans
  arrange(desc(means)) %>% # arrange decreasing by means
  distinct(transcript_id, .keep_all = TRUE) %>% # keep the ones with greatest mean value. If ties occur, keep the first occurencce
  select(-means) %>%
  unique() %>%
  remove_rownames() 

# Format for export
expr.input <- iso.collapsed %>% 
  column_to_rownames("transcript_id") %>%
  select(-c(gene_symbol)) 
print(dim(expr.input))

# save matrix
print("Saving collapsed matrix...")
saveRDS(object = expr.input, file = output.mat)
print("Done!!")

# Save file
saveRDS(isoform_final, file = isoform_collapsed_file)


