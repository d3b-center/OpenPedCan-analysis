suppressPackageStartupMessages({
  library(tidyverse)
})

# compare tp53 with broad histology molecular subtypes 
# base directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git")) 
analysis_dir <- file.path(root_dir, "analyses", "tp53_nf1_score")

# source function
source(file.path(analysis_dir, "util", "plot_by_molecular_subtype.R"))

# output directories
plots_dir <- file.path(analysis_dir, "plots")
results_dir <- file.path(analysis_dir, "results")

# read clinical data
hist_file <- file.path(root_dir, "data", "histologies.tsv") 
hist_file <- read_tsv(hist_file, guess_max = 100000)    
hist_file <- hist_file %>%
  filter(experimental_strategy == "RNA-Seq") %>%
  select(Kids_First_Biospecimen_ID, cancer_group, molecular_subtype) %>%
  rename("Kids_First_Biospecimen_ID_RNA" = "Kids_First_Biospecimen_ID") %>%
  unique()

# read tp53_scores (output of 05-tp53-altered-annotation.Rmd)
tp53_scores <- file.path(analysis_dir, "results", "tp53_altered_status.tsv") 
tp53_scores <- read.delim(tp53_scores) 
tp53_scores <- tp53_scores %>%
  filter(!is.na(tp53_score),
         !is.na(sample_id)) %>%
  select(-c(Kids_First_Biospecimen_ID_DNA)) %>%
  unique()

# merge clinical data with tp53 scores
tp53_scores <- hist_file %>%
  select(Kids_First_Biospecimen_ID_RNA, cancer_group, molecular_subtype) %>%
  unique() %>%
  inner_join(tp53_scores,  by = "Kids_First_Biospecimen_ID_RNA") %>%
  unique()

# filter NA, to be classified and reduce to sample count >= 3
tp53_scores <- tp53_scores %>%
  filter(!is.na(molecular_subtype),
         !grepl("To be classified", molecular_subtype)) %>%
  group_by(cancer_group, molecular_subtype) %>%
  mutate(n_samples = n()) %>%
  filter(n_samples >= 3)

# use molecular subtype count > 1 
subtypes <- tp53_scores %>%
  select(cancer_group, molecular_subtype) %>%
  unique() %>%
  group_by(cancer_group) %>%
  mutate(n_subtypes = n()) %>%
  filter(n_subtypes > 1)
tp53_scores <- tp53_scores %>%
  filter(molecular_subtype %in% subtypes$molecular_subtype)

# apply function
# create violin plot of TP53 scores per molecular subtype per histology 
plyr::d_ply(tp53_scores, 
            .variables = "cancer_group", 
            .fun = function(x) plot_by_molecular_subtype(scores_mat = x, plots_dir, results_dir))
