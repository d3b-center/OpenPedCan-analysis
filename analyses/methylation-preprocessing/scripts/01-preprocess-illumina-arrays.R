# Prepocess raw Illumina Infinium HumanMethylation BeadArrays (450K, and 850k) 
# intensities using minfi into usable methylation measurements (Beta and M values) 
# and copy number (cn-values) for OpenPedCan.

# Eric Wafula for Pediatric OpenTargets
# 09/28/2022

# Load libraries:
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tidyverse))
suppressWarnings(
  suppressPackageStartupMessages(library(minfi))
)

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# set up optparse options
option_list <- list(
  make_option(opt_str = "--base_dir", type = "character", default = NULL,
              help = "The absolute path of the base directory containing sample 
              array IDAT files.",
              metavar = "character"),
  
  make_option(opt_str = "--controls_present", action = "store_true", 
              default = TRUE,
              help = "preprocesses the Illumina methylation arrays using one of
              the following minfi normalization methods: 
              - preprocessFunnorm: when array dataset contains either control
                                   samples (i.e., normal and tumor samples) or 
                                   multiple OpenPedcan cancer groups (TRUE)
              - preprocessQuantile: when an array dataset has only tumor samples
                                    from a single OpenPedcan cancer group (FALSE)
              Default is TRUE (preprocessFunnorm)",
              metavar = "character"),
  
  make_option(opt_str = "--snp_filter", action = "store_true", default = TRUE, 
              help = "If TRUE, drops the probes that contain either a SNP at
              the CpG interrogation or at the single nucleotide extension.
              Default is TRUE",
              metavar = "character")
)


# parse parameter options
opt <- parse_args(OptionParser(option_list = option_list))
base_dir <- opt$base_dir
controls_present <- opt$controls_present
snp_filter <- opt$snp_filter

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module, data and results directories
module_dir <- file.path(root_dir, "analyses", "methylation-preprocessing")
data_dir <- file.path(module_dir, "data")
results_dir <- file.path(module_dir, "results")

# Create results folder if it doesn't exist
if (!dir.exists(results_dir)) {
  dir.create(results_dir)
}

# get analysis cancer type from arrays base_dir
dataset <- basename(base_dir)
message("===============================================")
message(c("Preprocessing ", dataset, " sample array data files..."))
message("===============================================\n")

# Check of the array data sub-directory exists
array_data_dir <- file.path(data_dir, dataset)
stopifnot(dir.exists(array_data_dir))

########################### Read sample array data  ############################
message("Reading sample array data files...\n")

# load array data into a RGChannelSet object
RGset <- suppressWarnings(
  minfi::read.metharray.exp(base = base_dir, verbose = TRUE, force = TRUE)
)

####################### Pre-processing and normalization ########################
message("\nPre-processing and normalizing...\n")

# process data into a GenomicRatioSet object
if (controls_present) {
  # preprocessFunnorm
  GRset <- RGset %>% 
    minfi::preprocessFunnorm(nPCs=2, sex = NULL, bgCorr = TRUE, dyeCorr = TRUE, 
                             keepCN = TRUE, ratioConvert = TRUE, verbose = TRUE)
} else { 
  # processQuantile
  GRset <- RGset %>%  
    minfi::preprocessQuantile(fixOutliers = TRUE,  quantileNormalize = TRUE, 
                              stratified = TRUE, mergeManifest = TRUE, sex = NULL)
}
# delete RGChannelSet object to free memory
rm(RGset)

if (snp_filter) {
  ########################## Remove probes with SNPs ############################
  message("\nRemoving probes with SNPs...\n")
  
  # removing probes with SNPs inside the probe body 
  # or at the nucleotide extension
  GRset <- GRset %>% 
    minfi::addSnpInfo() %>% 
    minfi::dropLociWithSnps(snps=c("SBE","CpG"), maf=0)
}

############################## Generate results ###############################
message("Generate results...\n")

# extract relevant methylation values, copy number values and probe annotations
# from the GenomicRatioSet object

# get methylation m-values
message("- Writing m-values matrix to file...\n")
GRset %>% minfi::getM() %>% as.data.frame() %>% 
  tibble::rownames_to_column("Probe_ID") %>% tibble::as_tibble() %>% 
  readr::write_rds(file.path(results_dir, 
                             paste0(dataset, "-methyl-m-values.rds")))

# get methylation beta-values
message("- Writing beta-values matrix to file...\n")
GRset %>% minfi::getBeta() %>% as.data.frame() %>% 
  tibble::rownames_to_column("Probe_ID") %>% tibble::as_tibble() %>% 
  readr::write_rds(file.path(results_dir, 
                             paste0(dataset, "-methyl-beta-values.rds")))

# get copy number values
message("- Writing cn-values matrix to file...\n")
GRset %>% minfi::getCN() %>% as.data.frame() %>% 
  tibble::rownames_to_column("Probe_ID") %>% tibble::as_tibble() %>% 
  readr::write_rds(file.path(results_dir, 
                             paste0(dataset, "-methyl-cn-values.rds")))

# delete GenomicRatioSet object to free memory
rm(GRset)
