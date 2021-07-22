# R. Jin 2021
# Filter expression matrix containing all specimens to only normal specimens of specific type

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("tidyverse"))


option_list <- list(
  make_option(c("-e","--expressionMatrix"),type="character",
              help="expression matrix (TPM for samples that need to be zscore normalized .RDS)"),
  make_option(c("-c","--clinicalFile"),type="character",
              help="Histology file for all samples (.TSV) "),
  make_option(c("-s","--specimenTypes"),type="character",
              help="list of specimen types that we want normal expresion matrix"),
  make_option(c("-o","--outputPath"),type="character",
              help="path to the normal expression matrix that we are generating")
)

opt <- parse_args(OptionParser(option_list=option_list))
expressionMatrix<-opt$expressionMatrix
clinicalFile<-opt$clinicalFile
specimen_type_list <-unlist(strsplit(opt$specimenTypes,","))
outputPath<- opt$outputPath

#read in expression matrix with all specimens and only select 
expressionMatrix <- readRDS(expressionMatrix)

#read in clinical file to find the list of normal specimens
histology_df <- read.delim(clinicalFile, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
lapply(specimen_type_list, function(x){
  # filter to the names of the specimen based on gtex_group
  normal_specimen <- histology_df %>% filter(gtex_group == x) %>% 
    filter(experimental_strategy == "RNA-Seq") %>%
    tibble::column_to_rownames("Kids_First_Biospecimen_ID")
  # subset the expression matrix to only contain specimen type of interest
  normal_expression_matrix <- expressionMatrix %>% select(rownames(normal_specimen))
  # define output file name and generate output
  specimen_type_name <- tolower(gsub(" ", "_", x))
  file_name <- file.path(outputPath, paste0("gtex_", specimen_type_name, "_test_TPM_hg38.rds"))
  saveRDS(normal_expression_matrix, file_name)
})

# generate reference file that matches each cohort and cancer_group with gtex normal expression file

cohort_PBTA <- histology_df %>% filter(experimental_strategy == "RNA-Seq") %>% filter(sample_type == "Tumor") %>%
  filter(cohort == "PBTA") %>% select(cancer_group, cohort) %>% distinct() %>% mutate(tissue_type = "Brain") %>% 
  mutate(gtex_matrix = "gtex_brain_TPM_hg38.rds")

cohort_GMKF <- histology_df %>% filter(experimental_strategy == "RNA-Seq") %>% filter(sample_type == "Tumor") %>%
  filter(cohort == "GMKF") %>% select(cancer_group, cohort) %>% distinct() %>% mutate(tissue_type = "Adrenal Gland") %>% 
  mutate(gtex_matrix = "gtex_adrenal_gland_TPM_hg38.rds")

gtex_match_cg_cohort <- rbind(cohort_PBTA, cohort_GMKF)
readr::write_tsv(gtex_match_cg_cohort, "references/gtex_match_cg_test_cohort.tsv")
