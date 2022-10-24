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

# Filter to only WGS samples from tumors, where composition is not "Derived Cell Line"
wgs_samples <- histology_df %>%
  dplyr::filter(sample_type == "Tumor", 
                composition != "Derived Cell Line", 
                experimental_strategy == "WGS",
                !grepl("Metastatic secondary tumors", pathology_diagnosis, ignore.case = FALSE, perl = FALSE,
                       fixed = FALSE, useBytes = FALSE))

# generate WGS independent samples for each cohort
wgs_primary_each <- independent_dna_samples(wgs_samples, tumor_types = "primary", independent_level = "each-cohort", seed = 2020)
wgs_relapse_each <- independent_dna_samples(wgs_samples, tumor_types = "relapse", independent_level = "each-cohort", seed = 2020)
wgs_primary_plus_each <- independent_dna_samples(wgs_samples, tumor_types = "prefer_primary", independent_level = "each-cohort", seed = 2020)

# generate WGS independent samples for all cohorts
wgs_primary_all <- independent_dna_samples(wgs_samples, tumor_types = "primary", independent_level = "all-cohorts", seed = 2020)
wgs_relapse_all <- independent_dna_samples(wgs_samples, tumor_types = "relapse", independent_level = "all-cohorts", seed = 2020)
wgs_primary_plus_all <- independent_dna_samples(wgs_samples, tumor_types = "prefer_primary", independent_level = "all-cohorts", seed = 2020)

# save output for each cohort
wgs_primary_each_file <- file.path(out_dir, "independent-specimens.wgs.primary.eachcohort.tsv")
message(paste(nrow(wgs_primary_each), "WGS primary specimens for each cohort"))
wgs_primary_each %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>% 
  readr::write_tsv(wgs_primary_each_file)

wgs_relapse_each_file <- file.path(out_dir, "independent-specimens.wgs.relapse.eachcohort.tsv")
message(paste(nrow(wgs_relapse_each), "WGS relapse specimens for each cohort"))
wgs_relapse_each %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgs_relapse_each_file)

wgs_primplus_each_file <- file.path(out_dir, "independent-specimens.wgs.primary-plus.eachcohort.tsv")
message(paste(nrow(wgs_primary_plus_each), "WGS specimens (including non-primary) for each cohort"))
wgs_primary_plus_each %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgs_primplus_each_file)

# save output for all cohorts
wgs_primary_all_file <- file.path(out_dir, "independent-specimens.wgs.primary.tsv")
message(paste(nrow(wgs_primary_all), "WGS primary specimens for all cohorts"))
wgs_primary_all %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgs_primary_all_file)

wgs_relapse_all_file <- file.path(out_dir, "independent-specimens.wgs.relapse.tsv")
message(paste(nrow(wgs_relapse_all), "WGS relapse specimens for all cohorts"))
wgs_relapse_all %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgs_relapse_all_file)

wgs_primplus_all_file <- file.path(out_dir, "independent-specimens.wgs.primary-plus.tsv")
message(paste(nrow(wgs_primary_plus_all), "WGS specimens (including non-primary) for all cohorts"))
wgs_primary_plus_all %>% 
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgs_primplus_all_file)
