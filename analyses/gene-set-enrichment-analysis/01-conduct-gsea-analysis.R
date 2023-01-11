################################################################################
# This script conducts gene set enrichment analysis, specifically using the GSVA method [1] for scoring hallmark human pathway enrichment from RNA-Seq results.
#
# The GSVA scores (i.e., enrichment scores) are calculated to produce a **Gaussian distribution of scores** "under the null hypothesis of no change in the pathway activity throughout the sample population."
# The authors claim a benefit to this approach:
#   + "Penalizes deviations that are large in *both* tails"
#   + "Provides a 'normalization' of the enrichment score by subtracting potential noise
#   + "Emphasizes genes in pathways that are concordantly activated in one direction only"
#   + "For pathways containing genes strongly acting in both directions, the deviations with cancel each other out and show little or no enrichment."
#
# Written by Stephanie J. Spielman for CCDL ALSF, 2020
#
#
#
# ####### USAGE, assumed to be run from top-level of project:
# Rscript --vanilla 'analyses/gene-set-enrichment-analysis/01-conduct-gsea-analysis.R --input <expression input file> --output <output file for writing scores>
#     --input_file: The name of the input expression data file to use for calculating scores.
#     --output_file: The name of the TSV-formatted output file of GSVA scores.
#     --hist_file: Histology file used.

#
# Reference:
# 1. Sonja Hänzelmann, Robert Castelo, and Justin Guinney. 2013. “GSVA: Gene Set Variation Analysis for Microarray and RNA-Seq Data.” BMC Bioinformatics 14 (1): 7. https://doi.org/10.1186/1471-2105-14-7.
################################################################################



#### Set Up Libraries --------------------------------------------------------------------

## Load and/or install libraries ##
library(tidyverse)
library(readr)
library(tibble)
library(optparse)

# Magrittr pipe
`%>%` <- dplyr::`%>%`

library(msigdbr) ## Contains the hallmark data sets
library(GSVA)    ## Performs GSEA analysis


#### Set Up optparse --------------------------------------------------------------------

## Define arguments
option_list <- list(
  optparse::make_option(
    c("--input_file"),
    type = "character",
    default = NA,
    help = "The input file of expression data from which scores will be calculated."
  ),
  optparse::make_option(
    c("--output_file"),
    type = "character",
    default = NA,
    help = "The output file for writing GSVA scores in TSV format."
  ),
  optparse::make_option(
    c("--histology"),
    type = "character",
    default = NA,
    help = "Histology file containing clinical information in TSV format."
  )
)

## Read in arguments
opt_parser <- optparse::OptionParser(option_list = option_list)
opt <- optparse::parse_args(opt_parser)


if (is.na(opt$input_file)) stop("\n\nERROR: You must provide an input file with expression data with the flag --input, assumed to be in the `data/` directory of the OpenPBTA repository..")
if (is.na(opt$output_file)) stop("\n\nERROR: You must provide an output file for saving GSVA scores with the flag --output, assumed to be placed in the `results/` directory of this analysis.")


#### Set Up paths and file names --------------------------------------------------------------------

# If the output directory does not exist, create it
output_dir <- dirname(opt$output_file)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

## Ensure the input file exists in `data/` and specify input/output files
expression_data_file <- opt$input_file
if (!file.exists(expression_data_file)) stop("\n\nERROR: Provided input file does not exist.")
scores_output_file <- file.path(output_dir, basename(opt$output_file))

#### Load input files --------------------------------------------------------------------
expression_data <- as.data.frame( readr::read_rds(expression_data_file) )
human_hallmark  <- msigdbr::msigdbr(species = "Homo sapiens", category = "H") ## human hallmark genes from `migsdbr` package. The loaded data is a tibble.

histology_df <- readr::read_tsv(opt$histology, guess_max = 100000)

#### Prepare hallmark genes: Create a list of hallmarks, each of which is a list of genes -----------------------------------------------
human_hallmark_twocols <- human_hallmark %>% dplyr::select(gs_name, human_gene_symbol)
human_hallmark_list    <- base::split(human_hallmark_twocols$human_gene_symbol, list(human_hallmark_twocols$gs_name))

#### Perform gene set enrichment analysis --------------------------------------------------------------------

# Prepare expression data: log2 transform re-cast as matrix
# filter to RNA and exclude TCGA and GTEx
histology_rna_df <- histology_df %>% 
  dplyr::filter(experimental_strategy == "RNA-Seq") %>% 
  dplyr::filter(!is.na(RNA_library)) %>%
  dplyr::filter(cohort != "TCGA") %>%
  dplyr::filter(!is.na(broad_histology)) %>%
  dplyr::filter(broad_histology != "Non-tumor") %>%  
  dplyr::filter(broad_histology != "Other tumor") %>%
  dplyr::filter(!is.na(cancer_group)) 
  

# First filter expression data to exclude GTEx and TCGA
expression_data <- expression_data %>% 
  dplyr::select(histology_rna_df$Kids_First_Biospecimen_ID)

# for each type of the RNA library, we subset the expression matrix accordingly and run gsea scores for each RNA library 
rna_library_list <- histology_rna_df %>% pull(RNA_library) %>% unique()
# Further subset to each cohort to deal with size issues
cohort_list <- histology_rna_df %>% pull(cohort) %>% unique()

gsea_scores_df_tidy <- data.frame()

# iterate through each cohort and RNA library type 
for(i in 1:length(rna_library_list)){
  rna_library = rna_library_list[i]
  # get bs id for one particular rna library type
  rna_library_type_bs_id <- histology_rna_df %>% 
    dplyr::filter(RNA_library == rna_library) %>% 
    pull(Kids_First_Biospecimen_ID) %>%
    unique()
  
  # Filter the expression data to this RNA library type
  # Subset to the remaining samples 
  expression_data_each <- expression_data %>% 
    dplyr::select(rna_library_type_bs_id)
  
  ### Rownames are genes and column names are samples
  expression_data_each_log2_matrix <- as.matrix( log2(expression_data_each + 1) )
  
  # Renmove genes with 0 variance
  #keep <- apply(expression_data_each_log2_matrix, 1, function(x) var(x, na.rm = TRUE)) > 0 
  #expression_data_each_log2_matrix_keep <- data.matrix(expression_data_each_log2_matrix[keep,])
                
  #We then calculate the Gaussian-distributed scores
  gsea_scores_each <- GSVA::gsva(expression_data_each_log2_matrix,
                                 human_hallmark_list,
                                 method = "gsva",
                                 min.sz=1, max.sz=1500,## Arguments from K. Rathi
                                 parallel.sz = 8, # For the bigger dataset, this ensures this won't crash due to memory problems
                                 mx.diff = TRUE)        ## Setting this argument to TRUE computes Gaussian-distributed scores (bimodal score distribution if FALSE)
  
  ### Clean scoring into tidy format
  gsea_scores_each_df <- as.data.frame(gsea_scores_each) %>%
    rownames_to_column(var = "hallmark_name")
  
  #first/last_bs needed for use in gather (we are not on tidyr1.0)
  first_bs <- head(colnames(gsea_scores_each), n=1)
  last_bs  <- tail(colnames(gsea_scores_each), n=1)
  
  rna_library<-gsub(" ", "_", rna_library)
  rna_library<-stringr::str_to_lower(gsub("-", "", rna_library))
  
  gsea_scores_each_df_tidy <- gsea_scores_each_df %>%
    tidyr::gather(Kids_First_Biospecimen_ID, gsea_score, !!first_bs : !!last_bs) %>%
    dplyr::select(Kids_First_Biospecimen_ID, hallmark_name, gsea_score) %>%
    dplyr::mutate(data_type = rna_library)
  
  gsea_scores_df_tidy <-  bind_rows(gsea_scores_df_tidy , gsea_scores_each_df_tidy)
}


#### Export GSEA scores to TSV --------------------------------------------------------------------
write_tsv(gsea_scores_df_tidy, scores_output_file)

#### Session info
sessionInfo()

