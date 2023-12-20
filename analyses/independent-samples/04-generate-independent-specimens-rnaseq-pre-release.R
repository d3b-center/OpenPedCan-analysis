# load libraries
library(magrittr)
library(dplyr)

# base directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
analysis_dir <- file.path(root_dir, "analyses", "independent-samples")

# create input_dir if doesn't exist
input_dir <- file.path(analysis_dir, "inputs")
if (!dir.exists(input_dir)) {
  dir.create(input_dir, recursive = TRUE)
}

# create out_dir if doesn't exist
out_dir <- file.path(analysis_dir, "results")
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}



# source function
source(file.path(analysis_dir, "util", "independent-rna-samples.R"))

# read pedcbio autopsy samples QC file (from Miguel)
autopsy_samples <- 
  readr::read_tsv(file.path(input_dir, "imperfect_cbio_sample.txt"), 
                  guess_max=100000) %>% 
  dplyr::select(sq_id, kf_biospecimen_id) %>% 
  dplyr::rename(sample_id = sq_id, 
                Kids_First_Biospecimen_ID = kf_biospecimen_id) %>% 
  dplyr::distinct()

# read histologies base file
histology_df <- 
  readr::read_tsv(file.path(root_dir, 'data/histologies-base.tsv'), 
                  guess_max=100000)

# subset histologies base for autopsy samples and update "sample_id"
autopsy_hist_df <- histology_df %>% 
  dplyr::filter(Kids_First_Biospecimen_ID %in% 
                  unique(autopsy_samples$Kids_First_Biospecimen_ID)) %>% 
  dplyr::select(-sample_id) %>% 
  dplyr::left_join(autopsy_samples, by = "Kids_First_Biospecimen_ID")

# update histologies base
histology_df <- histology_df %>% 
  dplyr::filter(!Kids_First_Biospecimen_ID %in% 
                  unique(autopsy_samples$Kids_First_Biospecimen_ID)) %>%
  dplyr::bind_rows(autopsy_hist_df)


# randomize rows of histology file to avoid selection bias
set.seed(100)
histology_df <- histology_df[sample(nrow(histology_df)), ]

# Filter to only samples from tumors from RNA-Seq minus GTEX
# ignored for now. Note that there are some samples with unknown composition, 
# but these will be 

rnaseq_samples <- histology_df %>%
  dplyr::filter(sample_type == "Tumor", 
                !composition %in% c("Derived Cell Line", "Patient Derived Xenograft"), 
                experimental_strategy == "RNA-Seq",
                !grepl("Metastatic secondary tumors", pathology_diagnosis, 
                       ignore.case = FALSE, perl = FALSE,
                       fixed = FALSE, useBytes = FALSE))

print(nrow(rnaseq_samples))
# generate release RNA-Seq independent samples for all cohorts
rnaseq_primary_all <- 
  independent_rna_samples(histology_df = rnaseq_samples, 
                          match_type = "none", 
                          tumor_description_rna_only = "primary", 
                          independent_level = "all-cohorts-pre-release", 
                          seed = 2020)
rnaseq_relapse_all <- 
  independent_rna_samples(histology_df = rnaseq_samples, 
                          match_type = "none", 
                          tumor_description_rna_only = "relapse", 
                          independent_level = "all-cohorts-pre-release", 
                          seed = 2020)
rnaseq_primary_plus_all <- 
  independent_rna_samples(histology_df = rnaseq_samples, 
                          match_type = "none", 
                          tumor_description_rna_only = "primary_plus", 
                          independent_level = "all-cohorts-pre-release", 
                          seed = 2020)


# save output for all cohorts
rnaseq_primary_all_file <- 
  file.path(out_dir, "independent-specimens.rnaseq.primary-pre-release.tsv")
message(paste(nrow(rnaseq_primary_all), 
              "RNA-Seq primary specimens for all cohorts"))
rnaseq_primary_all %>% 
  readr::write_tsv(rnaseq_primary_all_file)

rnaseq_relapse_all_file <- 
  file.path(out_dir, "independent-specimens.rnaseq.relapse-pre-release.tsv")
message(paste(nrow(rnaseq_relapse_all), 
              "RNA-Seq relapse specimens for all cohorts"))
rnaseq_relapse_all %>% 
  readr::write_tsv(rnaseq_relapse_all_file)

rnaseq_primplus_all_file <- 
  file.path(out_dir, "independent-specimens.rnaseq.primary-plus-pre-release.tsv")
message(paste(nrow(rnaseq_primary_plus_all), 
              "RNA-Seq specimens (including non-primary) for all cohorts"))
rnaseq_primary_plus_all %>% 
  readr::write_tsv(rnaseq_primplus_all_file)
