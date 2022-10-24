# Purpose: Generate tables of independent rna-seq specimens 

# load libraries
library(magrittr)
library(dplyr)
library(readr)

# base directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
analysis_dir <- file.path(root_dir, "analyses", "independent-samples")
out_dir <- file.path(analysis_dir, "results")
dir.create(out_dir, showWarnings = F, recursive = T)

# source function
source(file.path(analysis_dir, "util", "independent-methyl-samples.R"))

# read histology file
histology_df <- readr::read_tsv(file.path(root_dir, 'data/histologies.tsv'), guess_max=100000)

# randomize rows of histology file to avoid selection bias
set.seed(100)
histology_df <- histology_df[sample(nrow(histology_df)), ]

# Read in RNA-seq independent sample list to match to methly samples
# So that independent RNA samples match the methyl samples
independent_rna_sample_df_each <- readr::read_tsv("results/independent-specimens.rnaseqpanel.primary-plus.eachcohort.tsv")
independent_rna_sample_df_all <- readr::read_tsv("results/independent-specimens.rnaseqpanel.primary-plus.tsv")

# Filter for tumor samples where composition is not Derived Cell Line
histology_df <- histology_df %>%
  dplyr::filter(sample_type == "Tumor",
                composition != "Derived Cell Line",
                !grepl("Metastatic secondary tumors", pathology_diagnosis, ignore.case = FALSE, perl = FALSE,
                       fixed = FALSE, useBytes = FALSE)) 


# write independent sample outputs for independent levels of each cohort 
methyl_primary_each_file <- file.path(out_dir, "independent-specimens.methyl.primary.eachcohort.tsv")
independent_methyl_primary_each <- histology_df %>%
  independent_methyl_samples(independent_rna_sample_df = independent_rna_sample_df_each,
                             independent_level = "each-cohort",
                             histology_df = .,
                             match_type = "independent_rna_plus_only_methyl",
                             tumor_description_methyl_only = "primary", 
                             seed = 2020) %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>% 
  readr::write_tsv(methyl_primary_each_file)

methyl_relapse_each_file <- file.path(out_dir, "independent-specimens.methyl.relapse.eachcohort.tsv")
independent_methyl_relapse_each <- histology_df %>%
  independent_methyl_samples(independent_rna_sample_df = independent_rna_sample_df_each,
                             independent_level = "each-cohort",
                             histology_df = .,
                             match_type = "independent_rna_plus_only_methyl",
                             tumor_description_methyl_only = "relapse", 
                             seed = 2020) %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>% 
  readr::write_tsv(methyl_relapse_each_file)

methyl_primplus_each_file <- file.path(out_dir, "independent-specimens.methyl.primary-plus.eachcohort.tsv")
independent_methyl_primary_plus_each <- histology_df %>%
  independent_methyl_samples(independent_rna_sample_df = independent_rna_sample_df_each,
                             independent_level = "each-cohort",
                             histology_df = .,
                             match_type = "independent_rna_plus_only_methyl",
                             tumor_description_methyl_only = "primary_plus",
                             seed = 2020) %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>% 
  readr::write_tsv(methyl_primplus_each_file)

# write independent sample outputs for independent level of all cohorts 
methyl_primary_all_file <- file.path(out_dir, "independent-specimens.methyl.primary.tsv")
independent_methyl_primary_all <- histology_df %>%
  independent_methyl_samples(independent_rna_sample_df = independent_rna_sample_df_all,
                             independent_level = "all-cohorts",
                             histology_df = .,
                             match_type = "independent_rna_plus_only_methyl",
                             tumor_description_methyl_only = "primary",
                             seed = 2020) %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>% 
  readr::write_tsv(methyl_primary_all_file)

methyl_relapse_all_file <- file.path(out_dir, "independent-specimens.methyl.relapse.tsv")
independent_methyl_relapse_all <- histology_df %>%
  independent_methyl_samples(independent_rna_sample_df = independent_rna_sample_df_all,
                             independent_level = "all-cohorts",
                             histology_df = .,
                             match_type = "independent_rna_plus_only_methyl",
                             tumor_description_methyl_only = "relapse",
                             seed = 2020) %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>% 
  readr::write_tsv(methyl_relapse_all_file)

methyl_primplus_all_file <- file.path(out_dir, "independent-specimens.methyl.primary-plus.tsv")
independent_methyl_primary_plus_all <- histology_df %>%
  independent_methyl_samples(independent_rna_sample_df = independent_rna_sample_df_all,
                             independent_level = "all-cohorts",
                             histology_df = .,
                             match_type = "independent_rna_plus_only_methyl",
                             tumor_description_methyl_only = "primary_plus",
                             seed = 2020) %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>% 
  readr::write_tsv(methyl_primplus_all_file)
