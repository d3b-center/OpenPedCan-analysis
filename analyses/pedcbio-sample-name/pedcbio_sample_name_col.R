# Author: Run Jin
# Add PedCBio Sample Name Column Addition

suppressPackageStartupMessages({
  library("optparse")
  library("tidyverse")
  library("readr")
  library("tidyr")
})

#### Parse command line options ------------------------------------------------
option_list <- list(
  make_option(c("-i","--hist_dir"),type="character",
              help="input directory for the "))
opt <- parse_args(OptionParser(option_list=option_list,add_help_option = FALSE))
hist_dir <- opt$hist_dir

### Define directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
data_dir <- file.path(root_dir, "data")
analysis_dir <- file.path(root_dir, "analyses", "pedcbio-sample-name")
input_dir <- file.path(analysis_dir, "input")

results_dir <- file.path(analysis_dir, "results")
if(!dir.exists(results_dir)){
  dir.create(results_dir)
}

### Read in files
# histology file 
histology_df <- readr::read_tsv(file.path(hist_dir, "histologies.tsv"), guess_max = 100000)

# tmp update for broad histology bug, to be fixed in v11
histology_df <- histology_df %>%
  mutate(broad_histology = ifelse(broad_histology == "Hematologic malignancies", 
                                 "Hematologic malignancy", broad_histology),
         # move GTEX to cancer group for pedcbio viz
         cancer_group = case_when(
           cohort == "GTEx" ~ paste0(gtex_group, " (GTEx)"), 
           TRUE ~ as.character(cancer_group)),
         harmonized_diagnosis = case_when(
           cohort == "GTEx" ~ paste0(gtex_subgroup, " (GTEx)"),
         # add NBL subtyping to harm dx
           (cohort == "TARGET" | cohort == "GMKF") & !is.na(molecular_subtype) ~ paste0(cancer_group, ", ", molecular_subtype),
         # for remaining without a harm dx, use cancer group
         is.na(harmonized_diagnosis) ~ cancer_group, 
           TRUE ~ as.character(harmonized_diagnosis)))

filled_harm_dx <- histology_df %>%
  filter(!is.na(harmonized_diagnosis)) # 32652

table(histology_df$cohort) # 17382 gtex
table(histology_df$sample_type) # 15270 tumor 

# read in all the pedcbio files
cbio_names_list <- list.files(input_dir)

files_list <- lapply(cbio_names_list, function(x){
  x <- readr::read_csv(file.path(input_dir, x))
})


### Update the ID for those samples if available 
formatted_specimens_list <- lapply(files_list, function(x){
  
  # format them and select relevant columns
  formatted <- x %>% 
    dplyr::mutate(specimen_id = gsub("\\{", "", specimen_id)) %>% 
    dplyr::mutate(specimen_id = gsub("\\}", "", specimen_id)) %>% 
    dplyr::mutate(Kids_First_Biospecimen_ID = strsplit(specimen_id, ",")) %>% 
    tidyr::unnest(Kids_First_Biospecimen_ID) %>%
    dplyr::select(Kids_First_Biospecimen_ID, formatted_sample_id)
  
  # add those to histology file
  histology_formatted_added <- histology_df %>%
    dplyr::filter(Kids_First_Biospecimen_ID %in% formatted$Kids_First_Biospecimen_ID) %>%
    left_join(formatted)
  
  return(histology_formatted_added)
})

# get the combined data
combined_histology_formatted_added <- do.call("rbind", formatted_specimens_list)


### Add IDs to those without sample id already
# find the samples that do not have an ID yet 
histology_df_no_format_id <- histology_df %>%
  dplyr::filter(!Kids_First_Biospecimen_ID %in% combined_histology_formatted_added$Kids_First_Biospecimen_ID) 


#### Handle each cohort at a time - start with PBTA
# get all sample IDs in the PBTA cohort
sample_ids_pbta <- histology_df_no_format_id %>% 
  dplyr::filter(cohort == "PBTA") %>% 
  pull(sample_id) %>% 
  unique()

# find the samples that need additional `tie-breaker`
specimens_id_need_tiebreak <- c()

for (i in 1:length(sample_ids_pbta)){
  # deal with one sample at a time
  sample_id_of_interest <- sample_ids_pbta[i]
  
  # find the number of compositions
  each_specimen_need_tiebreak <- histology_df_no_format_id %>% 
    dplyr::filter(sample_type == "Tumor") %>% 
    dplyr::filter(sample_id == sample_id_of_interest) %>% 
    group_by(experimental_strategy) %>% 
    dplyr::mutate(n_sample_type = n()) %>%
    dplyr::filter(n_sample_type >1) %>%
    pull(Kids_First_Biospecimen_ID)
  
  # store the samples with multiple compositions
  specimens_id_need_tiebreak <- c(specimens_id_need_tiebreak, each_specimen_need_tiebreak)
}

# see the samples that need tiebreak
pbta_add_tiebreak <- histology_df_no_format_id %>% 
  dplyr::filter(Kids_First_Biospecimen_ID %in% specimens_id_need_tiebreak,
                sample_type != "Normal") 

# For DNA, we can use aliquot ID to separate them
# For RNA, different specimens are generated from the same aliqout but used different seuqencing method, hence RNA_library type can be used to separate them 
pbta_add_tiebreak <- pbta_add_tiebreak %>% 
  dplyr::mutate(formatted_sample_id = case_when(
    experimental_strategy == "RNA-Seq" ~ paste0(sample_id, "-", RNA_library),
    experimental_strategy != "RNA-Seq" ~ paste0(sample_id, "-", aliquot_id)
  ))

stopifnot(nrow(pbta_add_tiebreak) != unique(pbta_add_tiebreak$formatted_sample_id))

### Generate pedcbio ID for GTEx dataset 
# The format of the sample ID is GTEX-[donor ID]-[tissue site ID]-SM-[aliquot ID].
# The donor ID (e.g. GTEX-14753) should be used to link between the various RNA-seq and genotype samples that come from the same donor.
gtex_add_tiebreak <- histology_df_no_format_id %>% 
  dplyr::filter(cohort == "GTEx") %>%
  dplyr::mutate(formatted_sample_id = paste0(Kids_First_Participant_ID, "-", aliquot_id))

stopifnot(nrow(gtex_add_tiebreak) != unique(gtex_add_tiebreak$formatted_sample_id))


### Generate pedcbio ID for TARGET dataset 
# Similar to PBTA cohort, only need to add a tiebreak when multiple samples with the same experimental strategy
# The different is - we need to use `Kids_First_Participant_ID`

# get all participant IDs
participant_ids_target <- histology_df_no_format_id %>% 
  dplyr::filter(cohort == "TARGET") %>% 
  pull(Kids_First_Participant_ID) %>% 
  unique()

# find the samples that need additional `tie-breaker`
specimens_id_need_tiebreak <- c()

for (i in 1:length(participant_ids_target)){
  # deal with one sample at a time
  participant_of_interest <- participant_ids_target[i]
  
  # find the number of compositions
  each_specimen_need_tiebreak <- histology_df_no_format_id %>% 
    dplyr::filter(Kids_First_Participant_ID == participant_of_interest) %>% 
    group_by(experimental_strategy) %>% 
    dplyr::mutate(n_sample_type = n()) %>%
    dplyr::filter(n_sample_type >1) %>%
    pull(Kids_First_Biospecimen_ID)
  
  # store the samples with multiple compositions
  specimens_id_need_tiebreak <- c(specimens_id_need_tiebreak, each_specimen_need_tiebreak)
}

# see the samples that need tiebreak
target_add_tiebreak <- histology_df_no_format_id %>% 
  dplyr::filter(Kids_First_Biospecimen_ID %in% specimens_id_need_tiebreak) 

# For TARGET cohort, looks like using the last 7 digits from the specimen ID + Participant ID should be enough 
target_add_tiebreak <- target_add_tiebreak %>%
  dplyr::mutate(formatted_sample_id = gsub("^.{0,10}", "", Kids_First_Biospecimen_ID)) %>%
  dplyr::mutate(formatted_sample_id = case_when(
    sample_type == "Normal" ~ paste0(formatted_sample_id, "-N"),
    TRUE ~ formatted_sample_id
  ))
stopifnot(nrow(target_add_tiebreak) != unique(target_add_tiebreak$formatted_sample_id))


### Generate pedcbio ID for TCGA
# TCGA-{TSS}-{Participant}-{Sample Vial}-{Portion Analyte}-{Plate}-{Center}
# Again using the same method as PBTA and TARGET

# get all participant IDs
participant_ids_tcga <- histology_df_no_format_id %>% 
  dplyr::filter(cohort == "TCGA") %>% 
  pull(Kids_First_Participant_ID) %>% 
  unique()

# find the samples that need additional `tie-breaker`
specimens_id_need_tiebreak <- c()

for (i in 1:length(participant_ids_tcga)){
  # deal with one sample at a time
  participant_of_interest <- participant_ids_tcga[i]
  
  # find the number of compositions
  each_specimen_need_tiebreak <- histology_df_no_format_id %>% 
    dplyr::filter(Kids_First_Participant_ID == participant_of_interest) %>% 
    group_by(experimental_strategy) %>% 
    dplyr::mutate(n_sample_type = n()) %>%
    dplyr::filter(n_sample_type >1) %>%
    pull(Kids_First_Biospecimen_ID)
  
  # store the samples with multiple compositions
  specimens_id_need_tiebreak <- c(specimens_id_need_tiebreak, each_specimen_need_tiebreak)
}

# see the samples that need tiebreak
tcga_add_tiebreak <- histology_df_no_format_id %>% 
  dplyr::filter(Kids_First_Biospecimen_ID %in% specimens_id_need_tiebreak) 

# From what we can see, using Kids_First_Biospecimen_ID minus the center code is sufficient
tcga_add_tiebreak <- tcga_add_tiebreak %>%
  dplyr::mutate(formatted_sample_id = stringr::str_sub(Kids_First_Biospecimen_ID, start = 9, end = -4)) %>%
  dplyr::mutate(formatted_sample_id = case_when(
    sample_type == "Normal" ~ paste0(formatted_sample_id, "-N"),
    TRUE ~ formatted_sample_id
  ))

stopifnot(nrow(tcga_add_tiebreak) != unique(tcga_add_tiebreak$formatted_sample_id))

### Combine all the samples with tiebreak
# combine all tie break needed samples
all_tiebreaks <- bind_rows(combined_histology_formatted_added,
                           pbta_add_tiebreak,
                           gtex_add_tiebreak,
                           target_add_tiebreak,
                           tcga_add_tiebreak)

# for samples no need for tie break - use `sample_id` for PBTA and participant id for the rest
no_need_for_tiebreaks <- histology_df %>%
  dplyr::filter(!Kids_First_Biospecimen_ID %in% all_tiebreaks$Kids_First_Biospecimen_ID) %>%
  dplyr::mutate(formatted_sample_id = case_when(
    cohort == "PBTA" ~ sample_id,
    cohort == "DGD" ~ sample_id,
    TRUE ~ Kids_First_Participant_ID
))

# combine the files
histology_all_fixed <- bind_rows(all_tiebreaks, no_need_for_tiebreaks)

# write out the results
histology_all_fixed %>% 
  readr::write_tsv(file.path(results_dir, "histologies-formatted-id-added.tsv"))
