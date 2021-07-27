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
              help="path to the normal expression matrix that we are generating"),
  make_option(c("-m","--matchRef"),type="character",
              help="output file for the cohort + cancer_group match for normalization file (.TSV)")
)

opt <- parse_args(OptionParser(option_list=option_list))
expressionMatrix<-opt$expressionMatrix
clinicalFile<-opt$clinicalFile
specimen_type_list <-unlist(strsplit(opt$specimenTypes,","))
outputPath<- opt$outputPath
matchRef<-opt$matchRef

#read in expression matrix with all specimens and only select
expressionMatrix <- readRDS(expressionMatrix)

#read in clinical file to find the list of normal specimens
histology_df <- read.delim(clinicalFile, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
save<-lapply(specimen_type_list, function(x){
  # filter to the names of the specimen based on gtex_group
  normal_specimen <- histology_df %>% filter(gtex_group == x) %>%
    filter(experimental_strategy == "RNA-Seq") %>%
    tibble::column_to_rownames("Kids_First_Biospecimen_ID")
  # subset the expression matrix to only contain specimen type of interest
  normal_expression_matrix <- expressionMatrix %>% select(rownames(normal_specimen))
  # define output file name and generate output
  specimen_type_name <- tolower(gsub(" ", "_", x))
  file_name <- file.path(outputPath, paste0("gtex_", specimen_type_name, "_TPM_hg38.rds"))
  saveRDS(normal_expression_matrix, file_name)
})

### generate reference file that matches each cohort and cancer_group with gtex normal expression file
# filter to RNA-Seq tumor samples first
histology_df <-  histology_df %>% filter(experimental_strategy == "RNA-Seq") 

cohort_PBTA <- histology_df %>%
  filter(cohort == "PBTA") %>% select(cancer_group, cohort) %>% distinct() %>% mutate(tissue_type = "Brain") %>% 
  mutate(gtex_matrix = "gtex_brain_TPM_hg38.rds")

cohort_GMKF <- histology_df %>%
  filter(cohort == "GMKF") %>% select(cancer_group, cohort) %>% distinct() %>% mutate(tissue_type = "Adrenal Gland") %>% 
  mutate(gtex_matrix = "gtex_adrenal_gland_TPM_hg38.rds")

cohort_TARGET <- histology_df %>%
  filter(cohort == "TARGET") %>% select(cancer_group, cohort) %>% distinct() %>% 
  mutate(tissue_type = case_when(
    cancer_group %in% c("Acute Myeloid Leukemia", "Acute Lymphoblastic Leukemia") ~ "Blood",
    cancer_group %in% c("Wilms tumor","Rhabdoid tumor","Clear cell sarcoma of the kidney")  ~ "Kidney",
    cancer_group == "Neuroblastoma" ~ "Adrenal Gland",
    cancer_group == "Osteosarcoma" ~ "Bone",
    TRUE ~ "not available"
  )) %>% 
  mutate(gtex_matrix = case_when(
    tissue_type == "Kidney" ~ "gtex_kidney_TPM_hg38.rds",
    tissue_type == "Blood" ~ "gtex_blood_TPM_hg38.rds",
    tissue_type == "Adrenal Gland" ~ "gtex_adrenal_gland_TPM_hg38.rds",
    tissue_type == "Bone" ~ "not available",
    TRUE ~ "not available"))

gtex_match_cg_cohort <- rbind(cohort_PBTA, cohort_GMKF, cohort_TARGET)
readr::write_tsv(gtex_match_cg_cohort, matchRef)
