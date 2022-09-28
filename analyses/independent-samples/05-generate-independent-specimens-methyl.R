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
source(file.path(analysis_dir, "util", "independent-dna-samples.R"))

# read histology file
histology_df <- readr::read_tsv(file.path(root_dir, 'data/histologies.tsv'), guess_max=100000)

# randomize rows of histology file to avoid selection bias
set.seed(100)
histology_df <- histology_df[sample(nrow(histology_df)), ]

# Filter to only methylation samples from tumors, where composition is not "Derived Cell Line"
methyl_samples <- histology_df %>%
  dplyr::filter(sample_type == "Tumor", 
                composition != "Derived Cell Line", 
                experimental_strategy == "Methylation",
                !grepl("Metastatic secondary tumors", pathology_diagnosis, ignore.case = FALSE, perl = FALSE,
                       fixed = FALSE, useBytes = FALSE))

# generate methylation independent samples for all cohorts
methyl_primary_all <- independent_dna_samples(methyl_samples, 
                                              histology_df = histology_df, 
                                              tumor_types = "primary", 
                                              independent_level = "all-cohorts", 
                                              cohort_shortlist = "TARGET", 
                                              seed = 2020)
methyl_relapse_all <- independent_dna_samples(methyl_samples, 
                                              histology_df = histology_df, 
                                              tumor_types = "relapse", 
                                              independent_level = "all-cohorts", 
                                              cohort_shortlist = "TARGET", 
                                              seed = 2020)
methyl_primary_plus_all <- independent_dna_samples(methyl_samples, 
                                                   histology_df = histology_df, 
                                                   tumor_types = "prefer_primary", 
                                                   independent_level = "all-cohorts", 
                                                   cohort_shortlist = "TARGET", 
                                                   seed = 2020)


# save output for all cohorts
methyl_primary_all_file <- file.path(out_dir, "independent-specimens.methyl.primary.tsv")
message(paste(nrow(methyl_primary_all), "Methylation primary specimens for all cohorts"))
methyl_primary_all %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(methyl_primary_all_file)

methyl_relapse_all_file <- file.path(out_dir, "independent-specimens.methyl.relapse.tsv")
message(paste(nrow(methyl_relapse_all), "Methylation relapse specimens for all cohorts"))
methyl_relapse_all %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(methyl_relapse_all_file)

methyl_primplus_all_file <- file.path(out_dir, "independent-specimens.methyl.primary-plus.tsv")
message(paste(nrow(methyl_primary_plus_all), "Methylation specimens (including non-primary) for all cohorts"))
methyl_primary_plus_all %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(methyl_primplus_all_file)



# generate methylation independent samples for each cohort
methyl_primary_each <- independent_dna_samples(methyl_samples, 
                                              histology_df = histology_df, 
                                              tumor_types = "primary", 
                                              independent_level = "each-cohort", 
                                              cohort_shortlist = "TARGET", 
                                              seed = 2020)
methyl_relapse_each <- independent_dna_samples(methyl_samples, 
                                              histology_df = histology_df, 
                                              tumor_types = "relapse", 
                                              independent_level = "each-cohort", 
                                              cohort_shortlist = "TARGET", 
                                              seed = 2020)
methyl_primary_plus_each <- independent_dna_samples(methyl_samples, 
                                                   histology_df = histology_df, 
                                                   tumor_types = "prefer_primary", 
                                                   independent_level = "each-cohort", 
                                                   cohort_shortlist = "TARGET", 
                                                   seed = 2020)


# save output for each cohort
methyl_primary_each_file <- file.path(out_dir, "independent-specimens.methyl.primary.eachcohort.tsv")
message(paste(nrow(methyl_primary_each), "Methylation primary specimens for each cohort"))
methyl_primary_each %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(methyl_primary_each_file)

methyl_relapse_each_file <- file.path(out_dir, "independent-specimens.methyl.relapse.eachcohort.tsv")
message(paste(nrow(methyl_relapse_each), "Methylation relapse specimens for each cohort"))
methyl_relapse_each %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(methyl_relapse_each_file)

methyl_primplus_each_file <- file.path(out_dir, "independent-specimens.methyl.primary-plus.eachcohort.tsv")
message(paste(nrow(methyl_primary_plus_each), "Methylation specimens (including non-primary) for each cohort"))
methyl_primary_plus_each %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(methyl_primplus_each_file)

