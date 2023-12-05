# Create a subset for the the histologies-base.tsv with WGS samples missing
# in the GATK CNV calls to generate consensus calls if present in Manta SV caller

# Load libraries
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tidyverse))

# set up optparse options
option_list <- list(
  make_option(opt_str = "--histologies", type = "character", default = NULL,
              help = "OpenPedCan histogies base file",
              metavar = "character"),
  make_option(opt_str = "--cnv_gatk", type = "character", default = NULL,
              help = "GATK CNV calls file",
              metavar = "character"),
  make_option(opt_str = "--output", type = "character", default = NULL,
              help = "Subset hsitolgies base file of samples missing GATK CNV cal",
              metavar = "character")
)


# parse parameter options
opt <- parse_args(OptionParser(option_list = option_list))
histologies <- opt$histologies
cnv_gatk <- opt$cnv_gatk
output <- opt$output


# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))


# Set module input directory
module_dir <- file.path(root_dir, "analyses", "copy_number_consensus_call_manta")
input_dir <- file.path(module_dir, "input")


# Create input directory if it doesn't exist
if (!dir.exists(input_dir)) {
  dir.create(input_dir)
}


# get wgs samples in cnv gatk 
gtak_samples <- readr::read_tsv(cnv_gatk) %>% 
  dplyr::pull("BS_ID") %>%
  unique()


# subset histologies base for wgs tumor sample not in cnv gatk and write to file
readr::read_tsv(histologies) %>% 
  dplyr::filter(experimental_strategy == "WGS", sample_type == "Tumor",
                !Kids_First_Biospecimen_ID %in% gtak_samples) %>% 
  readr::write_tsv(output)
