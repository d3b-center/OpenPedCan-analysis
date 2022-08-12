# J. Taroni for CCDL 2019
# Updated by Eric Wafula for Pediatric Open Targets 2022
# This script takes a directory of OpenPedCan files to subset and produces a list
# of biospecimen IDs, saved as an RDS file, to use to subset the files for
# use in continuous integration.
#
# This list will have the following features, where each element is a vector
# of biospecimen IDs to be extracted from a file:
#
#   - Some number of biospecimen IDs that correspond to participant IDs that
#     are represented across experimental strategies. The number of participant
#     IDs used to accomplish this is specified with the num_matched parameter.
#     Participant IDs are selected proportional to the composition of RNA-Seq 
#     libraries in each cohorts.
#   - Some number of biospecimen IDs that correspond to participant IDs that
#     are *not* represented across strategies but are present in the file under
#     consideration. This number will be 10% of num_matched.
#   - We stratify based on `reported_gender`. The gender composition in all v11
#     cohorts is approximately balanced except for GTEx where the samples for
#     female participants are 50% of those for male participants. 
#   - We include (and hardcode) a set of biospecimen IDs for samples that have
#     TP53 and NF1 mutations that meet the criteria in the tp53_nf1_module and
#     are represented in the stranded RNA-seq dataset.
#     See 00-enrich-positive-examples for more information.
#
# EXAMPLE USAGE:
#
#   Rscript analyses/create-subset-files/01-get_biospecimen_identifiers.R \
#     --data_directory data/v11 \
#     --output_file analyses/create-subset-files/biospecimen_ids_for_subset.RDS \
#     --supported_string "snv|biospecimen|cnv|consensus_seg_with_status|fusion|sv-manta|.rds|independent" \
#     --num_matched 25 \
#     --seed 2019

#### Library and functions -----------------------------------------------------

suppressWarnings(
  suppressPackageStartupMessages(library(tidyverse))
)
suppressPackageStartupMessages(library(optparse))

`%>%` <- dplyr::`%>%`

get_biospecimen_ids <- function(filename, id_mapping_df) {
  # Given a supported OpenPedCan file, return the participant IDs corresponding
  # to the biospecimen IDs contained within that file
  #
  # Args:
  #   filename: the full path to a supported OpenPedCan file
  #   id_mapping_df: the data.frame that contains mapping between biospecimen
  #                  IDs and participant IDs
  #
  # Returns:
  #   a vector of unique participant IDs
  
  message(paste("Reading in", filename, "..."))
  
  if (grepl("snv", filename)) {
    # all SNV variant files keep the biospecimen identifiers in a column called
    # 'Tumor_Sample_Barcode'
    # if the files have consensus in the name, the first line of the file does
    # not contain MAF version information
    if (grepl("hotspots", filename)) {
      snv_file <- data.table::fread(filename,
                                    skip = 1,  # skip version string
                                    data.table = FALSE,
                                    showProgress = FALSE)
    } else {
      snv_file <- data.table::fread(filename, data.table = FALSE, 
                                    showProgress = FALSE)
    }
    # both kinds (original, consensus)
    biospecimen_ids <- unique(snv_file$Tumor_Sample_Barcode)
  } else if (grepl("biospecimen", filename)) {
    # list of sample IDs with their corresponding bed files
    bed_file <- readr::read_tsv(filename, show_col_types = FALSE)
    biospecimen_ids <- unique(bed_file$Kids_First_Biospecimen_ID)
  } else if (grepl("cnv", filename)) {
    # the two CNV files now have different structures
    cnv_file <- readr::read_tsv(filename, show_col_types = FALSE)
    if (grepl("controlfreec|cnvkit_with_status", filename)) {
      biospecimen_ids <- unique(cnv_file$Kids_First_Biospecimen_ID)
    } else if (grepl("consensus_wgs_plus_cnvkit_wxs", filename)) {
      biospecimen_ids <- unique(cnv_file$biospecimen_id)
    } else {
      biospecimen_ids <- unique(cnv_file$ID)
    }
  } else if (grepl("consensus_seg_with_status", filename)) {
    cn_seg_status_file <- readr::read_tsv(filename, 
                                          show_col_types = FALSE)
    biospecimen_ids <- unique(cn_seg_status_file$Kids_First_Biospecimen_ID)
  } else if (grepl("fusion", filename)) {
    fusion_file <- readr::read_tsv(filename, show_col_types = FALSE)
    # the biospecimen IDs in the filtered/prioritize fusion list included with
    # the download are in a column called 'Sample'
    if (grepl("putative-oncogenic", filename)) {
      biospecimen_ids <- unique(fusion_file$Sample)
    } else if(grepl("dgd", filename)) {
      biospecimen_ids <- unique(fusion_file$Tumor_Sample_Barcode)
    } else if (grepl("fusion_summary", filename)) {
      biospecimen_ids <- unique(fusion_file$Kids_First_Biospecimen_ID)
    } else {
      # the original files contain the relevant IDs in a column 'tumor_id'
      biospecimen_ids <- unique(fusion_file$tumor_id)
    }  
  } else if (grepl("sv-manta", filename)) {
    # in a column 'Kids.First.Biospecimen.ID.Tumor'
    sv_file <- data.table::fread(filename, data.table = FALSE, showProgress = FALSE)
    biospecimen_ids <- unique(sv_file$Kids.First.Biospecimen.ID.Tumor)
  } else if (grepl(".rds", filename)) {
    # RNA-Seq matrices column names
    if (grepl("rna-isoform", filename)) {
      expression_file <- readr::read_rds(filename) %>%
        dplyr::select(-transcript_id, -gene_symbol)
      biospecimen_ids <- unique(colnames(expression_file))
    } else {
      expression_file <- readr::read_rds(filename)
      biospecimen_ids <- unique(colnames(expression_file))
    }
  } else if (grepl("independent", filename)) {
    # in a column 'Kids_First_Biospecimen_ID'
    independent_file <- readr::read_tsv(filename, show_col_types = FALSE)
    biospecimen_ids <- unique(independent_file$Kids_First_Biospecimen_ID)
  } else {
    # error-handling
    stop("File type unrecognized by 'get_biospecimen_ids'")
  }
  # map from biospecimen ID to participant IDs and return unique participant IDs
  participant_ids <-  id_mapping_df %>%
    dplyr::filter(Kids_First_Biospecimen_ID %in% biospecimen_ids) %>%
    dplyr::pull(Kids_First_Participant_ID)
  return(unique(participant_ids))
}


select_participants_ids <- 
  function(histology, library, study, participants, match_ratio, match_value) {
    # Given a OpenPedCan histologies and participant IDs that are represented
    # across experimental strategies, returns selected cohort matched participant
    # IDs proportionally stratified by gender where applicable for subsetting
    #
    # Args:
    #   histology: dataframe of OpenPedCan histologies 
    #   library: RNA-Seq library type
    #   study: OpenPedCan cohort 
    #   participants: participant IDs that are represented across experimental 
    #                 strategies
    #   match_ratio: the proportion of the library cohort participant IDs to 
    #                select from the required number of matched participants
    #   match_value: the required number of matched participants per cohort 
    #
    # Returns:
    #   a vector of unique selected cohort matched participant IDs stratified
    #   by gender
    if (library == "other" ) {
      selected_participants <-  histology_df %>%
        dplyr::filter(RNA_library != "poly-A" | 
                        RNA_library != "stranded" | 
                        RNA_library != "poly-A stranded" |
                        RNA_library != "exome_capture",
                      cohort == study,
                      Kids_First_Participant_ID %in% participants)
      if (length(selected_participants$Kids_First_Participant_ID) == 0) {
        selected_participants <-  histology_df %>%
          dplyr::filter(RNA_library != "poly-A" | 
                          RNA_library != "stranded" |
                          RNA_library != "poly-A stranded" |
                          RNA_library != "exome_capture",
                        cohort == study)
        female <- selected_participants %>% 
          filter(reported_gender == "Female") %>% 
          dplyr::pull(Kids_First_Participant_ID) %>% unique()
        if (length(female) > ceiling(match_ratio * match_value)){
          female <- female %>% sample(ceiling(0.5 * match_ratio * match_value)) 
        }
        male <- selected_participants %>% 
          filter(reported_gender == "Male") %>% 
          dplyr::pull(Kids_First_Participant_ID) %>% unique()
        if (length(male) > ceiling(match_ratio * match_value)){
          male <- male %>% sample(ceiling(0.5 * match_ratio * match_value)) 
        }
        selected_participants <- c(female, male)
      } else {
        female <- selected_participants %>% 
          filter(reported_gender == "Female") %>% 
          dplyr::pull(Kids_First_Participant_ID) %>% unique()
        if (length(female) > ceiling(match_ratio * match_value)){
          female <- female %>% sample(ceiling(0.5 * match_ratio * match_value)) 
        }
        male <- selected_participants %>% 
          filter(reported_gender == "Male") %>% 
          dplyr::pull(Kids_First_Participant_ID) %>% unique()
        if (length(male) > ceiling(match_ratio * match_value)){
          male <- male %>% sample(ceiling(0.5 * match_ratio * match_value)) 
        }
        selected_participants <- c(female, male)
      }
      return(selected_participants)
    } else { # library == "poly-A" | library == "stranded" | library == "poly-A stranded" | library == "exome_capture"
      selected_participants <-  histology_df %>%
        dplyr::filter(RNA_library == library, cohort == study,
                      Kids_First_Participant_ID %in% participants) 
      if (length(selected_participants$Kids_First_Participant_ID) == 0) {
        selected_participants <-  histology_df %>%
          dplyr::filter(RNA_library == library, cohort == study)
        female <- selected_participants %>% 
          filter(reported_gender == "Female") %>% 
          dplyr::pull(Kids_First_Participant_ID) %>% unique()
        if (length(female) > ceiling(match_ratio * match_value)){
          female <- female %>% sample(ceiling(0.5 * match_ratio *  match_value)) 
        }
        male <- selected_participants %>% 
          filter(reported_gender == "Male") %>% 
          dplyr::pull(Kids_First_Participant_ID) %>% unique()
        if (length(male) > ceiling(match_ratio * match_value)){
          male <- male %>%sample(ceiling(0.5 * match_ratio * match_value)) 
        }
        selected_participants <- c(female, male)
      } else {
        female <- selected_participants %>% 
          filter(reported_gender == "Female") %>% 
          dplyr::pull(Kids_First_Participant_ID) %>% unique()
        if (length(female) > ceiling(match_ratio * match_value)){
          female <- female %>% sample(ceiling(0.5 * match_ratio * match_value)) 
        }
        male <- selected_participants %>% 
          filter(reported_gender == "Male") %>% 
          dplyr::pull(Kids_First_Participant_ID) %>% unique()
        if (length(male) > ceiling(match_ratio * match_value)){
          male <- male %>% sample(ceiling(0.5 * match_ratio * match_value)) 
        }
        selected_participants <- c(female, male)
      }
      return(selected_participants)
    }
  }

#### Command line arguments/options --------------------------------------------

# Declare command line options
option_list <- list(
  make_option(
    c("-d", "--data_directory"),
    type = "character",
    default = NULL,
    help = "directory that contains data files to subset",
  ),
  make_option(
    c("-o", "--output_file"),
    type = "character",
    default = NULL,
    help = "output RDS file"
  ),
  make_option(
    c("-r", "--supported_string"),
    type = "character",
    default = "snv|biospecimen|cnv|consensus_seg_with_status|fusion|sv-manta|.rds|independent",
    help = "string for pattern matching used to subset to only supported files"
  ),
  make_option(
    c("-p", "--num_matched"),
    type = "integer",
    default = 25,
    help = "number of matched participants",
    metavar = "integer"
  ),
  make_option(
    c("-s", "--seed"),
    type = "integer",
    default = 2019,
    help = "seed integer",
    metavar = "integer"
  ),
  make_option(
    c("-l", "--local"),
    type = "integer",
    default = 0,
    help = "0 or 1; setting to 1 will skip the larger MAF files for local testing"
  )
)

# Read the arguments passed
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Handle options for whether or not this is running locally on someone's laptop
if (opt$local == 0) {
  running_locally <- FALSE
} else if (opt$local == 1) {
  running_locally <- TRUE
} else {
  stop("--local must be 0 or 1!")
}

# set up required arguments: input directory and output file
data_directory <- opt$data_directory
output_file <- opt$output_file

# string that will be used for pattern matching to select the files for
# subsetting
supported_files_string <- opt$supported_string

# get numbers of matched participants
num_matched_participants <- opt$num_matched

# extra non-matched samples -- this is a realistic scenario and will test for
# brittleness of code up for review
num_nonmatched_participants <- ceiling(0.1 * num_matched_participants)

# set the seed
set.seed(opt$seed)

#### Samples we need to include to run tp53_nf1_score --------------------------

# For more information, see the 00-enrich-positive-examples notebook
tp53_dnaseq <- c("BS_16FT8V4B", "BS_B9QP40ER", "BS_7KR13R3P", "BS_K2K5YSDS", 
                 "TARGET-30-PAPBGH-01A-01W", "TARGET-40-PARGTM-01A-01D",
                 "TARGET-40-PATPBS-01A-01D")
tp53_rnaseq <- c("BS_E4QK839R", "BS_XZM79E42", "BS_8ZY4GST0", "BS_S5KDWVEA",
                 "TARGET-30-PAPBGH-01A-01R", "TARGET-40-PARGTM-01A-01R", 
                 "TARGET-40-PATPBS-01A-01R")
nf1_dnaseq <- c("BS_2J4FG4HV", "BS_QJHY513X", "BS_6DT506HY", 
                "TARGET-50-PAKKNS-01A-01D", "TARGET-30-PAPVRN-01A-01D",
                "TARGET-10-PANTSM-04A-01D")
nf1_rnaseq <- c("BS_81SP2HX4", "BS_KFD5128N", "BS_YDEVMD24", 
                "TARGET-50-PAKKNS-01A-01R", "TARGET-30-PAPVRN-01A-01R",
                "TARGET-10-PANTSM-04A-01R")

### Histologies and participants IDs mapping -----------------------------------

# load histologies file
histology_df <- read_tsv(file.path(data_directory, "histologies.tsv"), 
                         guess_max = 10000, show_col_types = FALSE) %>% 
  dplyr::filter(experimental_strategy != "Methylation")

# get the participant ID to biospecimen ID mapping
id_mapping_df <- histology_df %>%
  dplyr::select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID) %>%
  dplyr::distinct()

#### Get IDs -------------------------------------------------------------------

# list all files we are interested in subsetting and can support
files_to_subset <- list.files(data_directory,
                              pattern = supported_files_string,
                              full.names = TRUE)

# if testing this locally, drop the large consensus MAF file
if (running_locally) {
  files_to_subset <- files_to_subset[-grep("hotspots", files_to_subset)]
}

# drop GISTIC zipped file from this list 
files_to_subset <- files_to_subset[-grep("gistic.zip", files_to_subset)]

# drop methylation RDS matrices. The "methylation-summary" module that produces
# these matrices and consumes them alongside other data release files requires 
# the super large output files produced by the "methylation-preprocessing"  
# module that currently not part of the data release
# Methylation modules won't be tested with CI
files_to_subset <- files_to_subset[-grep("methyl", files_to_subset)]

# for each file, extract the participant ID list by first obtaining the
# biospecimen IDs and then mapping back to participant ID
message("\nGetting participant IDs from all files...")
participant_id_list <- purrr::map(files_to_subset,
                                  ~ get_biospecimen_ids(.x, id_mapping_df)) %>%
  purrr::set_names(files_to_subset)


# list of matched participant IDs, not including cohort-specific 
# file (TCGA and DGD)
message("\nGetting matched participant IDs, exclduing cohort-specific files ...")
other_participant_id_list <- 
  participant_id_list[-grep("tcga|dgd", names(participant_id_list))]
other_matched_participants <- purrr::reduce(other_participant_id_list,
                                                intersect)

# list of TCGA-specific rnaseq files and matched participant IDs for subsetting
message("\nGetting TCGA rna-seq matched participant IDs...")
tcga_participant_id_list <- 
  participant_id_list[grep("tcga", names(participant_id_list))]
tcga_matched_participants <- purrr::reduce(tcga_participant_id_list,
                                               intersect)

# list of DGD-specific panel files and matched participant IDs 
# for subsetting 
message("\nGetting DGD panel matched participant IDs...")
dgd_participant_id_list <- 
  participant_id_list[grep("dgd", names(participant_id_list))]
dgd_matched_participants <- purrr::reduce(dgd_participant_id_list,
                                              intersect)

#### Selected matched participant IDs stratified by gender ---------------------

# Participant IDs are selected proportionally to the composition of each 
# cohort's RNA-Seq libraries

# polya rnaseq matched participant IDs including a random set GTEx polya libraries
message("\nSelecting polya rnaseq matched participant IDs...")
polya_matched <- c(
  select_participants_ids(histology_df, "poly-A",  "PBTA",
                          other_matched_participants, 0.1, num_matched_participants),
  select_participants_ids(histology_df, "poly-A", "TARGET",
                          other_matched_participants, 0.1, num_matched_participants),
  select_participants_ids(histology_df, "poly-A stranded", "TARGET",
                          other_matched_participants, 0.6, num_matched_participants),
  select_participants_ids(histology_df, "poly-A", "TCGA",
                          tcga_matched_participants, 0.9, num_matched_participants),
  # GTEx Famele:Male == 0.3:0.7, other cohorts ~0.5 (balanced)
  histology_df %>% filter(cohort == "GTEx", reported_gender == "Female") %>%
    pull(Kids_First_Participant_ID) %>% unique() %>%
    sample(ceiling(0.3 * num_matched_participants)),
  histology_df %>% filter(cohort == "GTEx", reported_gender == "Male") %>%
    pull(Kids_First_Participant_ID) %>% unique() %>%
    sample(ceiling(0.7 * num_matched_participants))
)

# stranded rnaseq matched participant IDs
message("\nSelecting stranded rnaseq matched participant IDs...")
stranded_matched <- c(
  select_participants_ids(histology_df, "stranded",  "PBTA",
                          other_matched_participants, 0.89, num_matched_participants),
  select_participants_ids(histology_df, "stranded", "TARGET",
                          other_matched_participants, 0.3, num_matched_participants),
  select_participants_ids(histology_df, "stranded", "TCGA",
                          tcga_matched_participants, 0.1, num_matched_participants),
  select_participants_ids(histology_df, "stranded", "GMKF",
                          other_matched_participants, 1.0, num_matched_participants)
)

# exome_capture rnaseq matched participant IDs
message("\nSelecting exome capture rnaseq matched participant IDs...")
exome_capture_matched <- c(
  select_participants_ids(histology_df, "exome_capture",  "PBTA",
                          other_matched_participants, 0.01, num_matched_participants)
)

# other cohort-specific library types matched participant IDs, including panels 
# i.e., DGD exome capture rna sequencing and exome sequencing
message("\nSelecting other library types matched participant IDs...")
other_matched <- 
  select_participants_ids(histology_df, "other", "DGD",
                          dgd_matched_participants, 1.0, num_matched_participants)

#### Combining selected matched and nonmatched participant IDs for subsetting---

message("\nCombining selected matched and nonmatched participant IDs...")
# combine all matched participant IDs for subsetting
matched_participants_ids <- 
  unique(c(polya_matched, stranded_matched, exome_capture_matched, other_matched))

matched_participant_id_list <- purrr::map(
  participant_id_list, 
  function(x) { 
    x[x %in% matched_participants_ids] 
  }
)

# get a list of participants that are not in the matched lists
nonmatched_participant_id_list <-
  purrr::map(participant_id_list,
             ~ setdiff(.x, matched_participant_id_list)) %>%
  purrr::map(~ sample(.x, num_nonmatched_participants))

# combine matched and nonmatched lists of ids for subsetting
participant_ids_for_subset <- 
  purrr::map2(matched_participant_id_list, nonmatched_participant_id_list, c)

# map back matched participant IDs to biospecimen IDs
message("\nRetrieving biospecimen IDs for selected matched and nonmatched participant IDs...")
biospecimen_ids_for_subset <- purrr::map(
  participant_ids_for_subset,
  function(x) {
    id_mapping_df %>%
      dplyr::filter(Kids_First_Participant_ID %in% x) %>%
      dplyr::pull(Kids_First_Biospecimen_ID)
  }
)

message(paste0("\nAppending NF1 and TP53 mutations biospecimen IDs to rds and snv lists..."))

# for each rnaseq rds instance, add in biospecimen IDs for samples we know have
# a positive example of NF1 mutation and TP53 for tp53_nf1_score
rds_files <- 
  names(biospecimen_ids_for_subset[grep(".rds", names(biospecimen_ids_for_subset))])
rds_files <- rds_files[-grep("tcga", rds_files)]
biospecimen_ids_for_subset <- biospecimen_ids_for_subset %>%
  purrr::modify_at(rds_files, ~ append(.x, c(tp53_rnaseq, nf1_rnaseq)))

# for each snv instance, add in biospecimen IDs for samples we know have a
# positive example of NF1 mutation and TP53 for tp53_nf1_score
snv_index <- stringr::str_which(names(biospecimen_ids_for_subset), "snv")
biospecimen_ids_for_subset <- biospecimen_ids_for_subset %>%
  purrr::modify_at(snv_index, ~ append(.x, c(tp53_dnaseq, nf1_dnaseq)))

# remove any redundant that might result combining and appending to the 
# biospecimen IDs lists for subsetting 
biospecimen_ids_for_subset <- biospecimen_ids_for_subset %>% 
  purrr::map(~ unique(.x))

# writing biospecimen IDs to file
message(paste0("\nWriting biospecimen IDs to ", output_file, " file...\n"))
biospecimen_ids_for_subset %>% write_rds(output_file)


