# Author: Komal S. Rathi updated, 2020-07 Kelsey Keith
# script to perform immune characterization using R package immunedeconv

# load libraries
suppressPackageStartupMessages({
  library(optparse)
  library(tidyverse)
  library(immunedeconv)
})

# parse parameters
option_list <- list(
  make_option(c("--expr_mat"), type = "character",
              help = "expression data: gene symbol x sample identifiers (.rds)"),
  make_option(c("--clin_file"), type = "character",
              help = "histologies file (.tsv)"),
  make_option(c("--deconv_method"), type = "character",
              help = "deconvolution method"),
  make_option(c("--output_dir"), type = "character", 
              help = "output directory")
)

opt <- parse_args(OptionParser(option_list = option_list))
expr_mat <- opt$expr_mat
clin_file <- opt$clin_file
deconv_method <- tolower(opt$deconv_method)
output_dir <- opt$output_dir

# output file
dir.create(output_dir, showWarnings = F, recursive = T)
output_file <- file.path(output_dir, paste0(deconv_method, "_output.rds"))

# method should be one of xcell or quantiseq
if (!(deconv_method %in% c("xcell", "quantiseq")))
  stop("Error: deconv_method must be one of xcell or quantiseq")

# read expression data 
expr_mat <- readRDS(expr_mat)

# read clinical data
clin_file <- readr::read_tsv(clin_file, guess_max = 10000)
clin_file <- clin_file %>% 
  filter(Kids_First_Biospecimen_ID %in% colnames(expr_mat),
         experimental_strategy == "RNA-Seq",
         cohort == "GTEx" | !is.na(cancer_group)) # remove non-annotated samples

# process each group separately because xCell uses the variability among the samples for a linear transformation of the output score
# a group is a combination of cohort + cancer group or gtex group
n_groups <- clin_file %>%
  mutate(group = ifelse(cohort == "GTEx", gtex_group, cancer_group),
         group = paste0(cohort, "_", group)) %>%
  dplyr::select(Kids_First_Biospecimen_ID, group)
full_output <- plyr::dlply(.data = n_groups, .variables = "group", .fun = function(x) {
  
  # get kf ids for all samples in the group
  print(x %>% pull(group) %>% unique)
  kf_ids <- x %>%
    pull(Kids_First_Biospecimen_ID)
  
  # at least two samples are needed for processing
  if(length(kf_ids) < 2){
    print("Only one sample available; skip processing")
    return()
  }
  
  # subset input matrix to group
  expr_mat_sub <- expr_mat %>%
    dplyr::select(kf_ids)
  
  # deconvolute using specified method
  print("Starting deconvolution...")
  deconv_output <- deconvolute(gene_expression = as.matrix(expr_mat_sub), 
                               method = deconv_method, arrays = F)
  
  # convert to long format
  deconv_output <- deconv_output %>%
    as.data.frame() %>%
    gather(Kids_First_Biospecimen_ID, fraction, -c(cell_type)) %>%
    as.data.frame()
})

# combine all groups
full_output <- dplyr::bind_rows(full_output)

# merge output with clinical data
full_output <- clin_file %>% 
  dplyr::select(Kids_First_Biospecimen_ID, cohort, sample_type, gtex_group, gtex_subgroup, cancer_group, molecular_subtype) %>%
  inner_join(full_output, by = "Kids_First_Biospecimen_ID") %>%
  mutate(method = deconv_method)

# save output to rds file
print("Writing output to file...")
saveRDS(object = full_output, file = output_file)
print("Done!")
