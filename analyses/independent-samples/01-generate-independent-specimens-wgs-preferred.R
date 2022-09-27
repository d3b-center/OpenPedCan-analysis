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

# Filter to only samples from tumors, where composition is not "Derived Cell Line".
tumor_samples <- histology_df %>%
  dplyr::filter(sample_type == "Tumor", 
                composition != "Derived Cell Line", 
                is.na(RNA_library), 
                experimental_strategy %in% c("WGS", "WXS", "Targeted Sequencing"),
                !grepl("Metastatic secondary tumors", pathology_diagnosis, ignore.case = FALSE, perl = FALSE,
                       fixed = FALSE, useBytes = FALSE))

# subset to WGS samples only
wgs_samples <- tumor_samples %>%
  dplyr::filter(experimental_strategy == "WGS")

# generate WGS independent samples for each cohort
wgs_primary_each <- independent_dna_samples(wgs_samples, tumor_types = "primary", independent_level = "each-cohort", seed = 2020)
wgs_relapse_each <- independent_dna_samples(wgs_samples, tumor_types = "relapse", independent_level = "each-cohort", seed = 2020)
wgs_primary_plus_each <- independent_dna_samples(wgs_samples, tumor_types = "prefer_primary", independent_level = "each-cohort", seed = 2020)

# generate WGS independent samples for all cohorts
wgs_primary_all <- independent_dna_samples(wgs_samples, tumor_types = "primary", independent_level = "all-cohorts", seed = 2020)
wgs_relapse_all <- independent_dna_samples(wgs_samples, tumor_types = "relapse", independent_level = "all-cohorts", seed = 2020)
wgs_primary_plus_all <- independent_dna_samples(wgs_samples, tumor_types = "prefer_primary", independent_level = "all-cohorts", seed = 2020)

# subset to WXS samples only
# WGS is preferred, include WXS samples where WGS is not available
wxs_samples <-  tumor_samples %>% 
  dplyr::filter(experimental_strategy == "WXS")

# each cohort
wxs_primary_each <- independent_dna_samples(wxs_samples, tumor_types = "primary", independent_level = "each-cohort", seed = 2020)
wxs_relapse_each <- independent_dna_samples(wxs_samples, tumor_types = "relapse", independent_level = "each-cohort", seed = 2020)
wxs_primary_plus_each <- independent_dna_samples(wxs_samples, tumor_types = "prefer_primary", independent_level = "each-cohort", seed = 2020)

# all cohorts
wxs_primary_all <- independent_dna_samples(wxs_samples, tumor_types = "primary", independent_level = "all-cohorts", seed = 2020)
wxs_relapse_all <- independent_dna_samples(wxs_samples, tumor_types = "relapse", independent_level = "all-cohorts", seed = 2020)
wxs_primary_plus_all <- independent_dna_samples(wxs_samples, tumor_types = "prefer_primary", independent_level = "all-cohorts", seed = 2020)


# subset to panel samples only
# WGS is preferred followed by WXS, include panel samples where WGS and WXS are not available
panel_samples <-  tumor_samples %>% 
  dplyr::filter(experimental_strategy == "Targeted Sequencing")

# each cohort
panel_primary_each <- independent_dna_samples(panel_samples, tumor_types = "primary", independent_level = "each-cohort", seed = 2020)
panel_relapse_each <- independent_dna_samples(panel_samples, tumor_types = "relapse", independent_level = "each-cohort", seed = 2020)
panel_primary_plus_each <- independent_dna_samples(panel_samples, tumor_types = "prefer_primary", independent_level = "each-cohort", seed = 2020)

# all cohorts
panel_primary_all <- independent_dna_samples(panel_samples, tumor_types = "primary", independent_level = "all-cohorts", seed = 2020)
panel_relapse_all <- independent_dna_samples(panel_samples, tumor_types = "relapse", independent_level = "all-cohorts", seed = 2020)
panel_primary_plus_all <- independent_dna_samples(panel_samples, tumor_types = "prefer_primary", independent_level = "all-cohorts", seed = 2020)

# save output for each cohort 
# for each cohort we take distinct Kids_First_Participant_ID + cohort combination
wgswxspanel_primary_each_file <- file.path(out_dir, "independent-specimens.wgswxspanel.primary.eachcohort.prefer.wgs.tsv")
output <- rbind(wgs_primary_each, wxs_primary_each, panel_primary_each) %>%
  distinct(Kids_First_Participant_ID, cohort, .keep_all = TRUE)
message(paste(nrow(output), "WGS+WXS+Panel primary specimens for each cohort"))
output %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgswxspanel_primary_each_file)

wgswxspanel_relapse_each_file <- file.path(out_dir, "independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wgs.tsv")
output <- rbind(wgs_relapse_each, wxs_relapse_each, panel_relapse_each) %>%
  distinct(Kids_First_Participant_ID, cohort, .keep_all = TRUE)
message(paste(nrow(output), "WGS+WXS+Panel relapse specimens for each cohort"))
output %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgswxspanel_relapse_each_file)

wgswxspanel_primplus_each_file <- file.path(out_dir, "independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wgs.tsv")
output <- rbind(wgs_primary_plus_each, wxs_primary_plus_each, panel_primary_plus_each) %>%
  distinct(Kids_First_Participant_ID, cohort, .keep_all = TRUE)
message(paste(nrow(output), "WGS+WXS+Panel specimens (including non-primary) for each cohort"))
output %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgswxspanel_primplus_each_file)

# save output for all cohorts
# for all cohorts we take distinct Kids_First_Participant_ID only
wgswxspanel_primary_all_file <- file.path(out_dir, "independent-specimens.wgswxspanel.primary.prefer.wgs.tsv")
output <- rbind(wgs_primary_all, wxs_primary_all, panel_primary_all) %>%
  distinct(Kids_First_Participant_ID, .keep_all = TRUE)
message(paste(nrow(output), "WGS+WXS+Panel primary specimens for all cohort"))
output %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgswxspanel_primary_all_file)

wgswxspanel_relapse_all_file <- file.path(out_dir, "independent-specimens.wgswxspanel.relapse.prefer.wgs.tsv")
output <- rbind(wgs_relapse_all, wxs_relapse_all, panel_relapse_all) %>%
  distinct(Kids_First_Participant_ID, .keep_all = TRUE)
message(paste(nrow(output), "WGS+WXS+Panel relapse specimens for all cohort"))
output %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgswxspanel_relapse_all_file)

wgswxspanel_primplus_all_file <- file.path(out_dir, "independent-specimens.wgswxspanel.primary-plus.prefer.wgs.tsv")
output <- rbind(wgs_primary_plus_all, wxs_primary_plus_all, panel_primary_plus_all) %>%
  distinct(Kids_First_Participant_ID, .keep_all = TRUE)
message(paste(nrow(output), "WGS+WXS+Panel specimens (including non-primary) for all cohort"))
output %>%
  dplyr::arrange(Kids_First_Biospecimen_ID) %>%
  readr::write_tsv(wgswxspanel_primplus_all_file)

