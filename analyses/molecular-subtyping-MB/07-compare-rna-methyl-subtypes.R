# Author: Ryan Corbett
# Function: compare MB molecular subtypes defined by RNA and DNA methylation data modalities 

# load libraries
library(tidyverse)
library(data.table)

# Set up directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

data_dir <- file.path(root_dir, "data")
analysis_dir <- file.path(root_dir, "analyses", "molecular-subtyping-MB")
input_dir <- file.path(analysis_dir, "input")
results_dir <- file.path(analysis_dir, "results")
plot_dir <- file.path(analysis_dir, "plots")

# If the directory does not exist, create it
if (!dir.exists(results_dir)) {
  dir.create(results_dir, recursive = TRUE)
}

# set histologies file path
hist_file <- file.path(data_dir, "histologies.tsv")

# wrangle data
hist <- read_tsv(hist_file)

# subset hist for MB methylation samples and subtyping
hist_mb_methyl <- hist %>%
  dplyr::filter(experimental_strategy == "Methylation",
                cancer_group == "Medulloblastoma",
                dkfz_v12_methylation_subclass_score >= 0.8) %>%
  dplyr::select(Kids_First_Participant_ID,
                match_id,
                experimental_strategy,
                molecular_subtype_methyl,
                dkfz_v12_methylation_subclass)

# subset hist for MB RNA samples and subtyping
hist_mb_rna <- hist %>%
  dplyr::filter(experimental_strategy == "RNA-Seq",
                cancer_group == "Medulloblastoma") %>%
  dplyr::select(Kids_First_Participant_ID,
                match_id,
                experimental_strategy,
                molecular_subtype) %>%
  dplyr::rename(molecular_subtype_rna = molecular_subtype)

# merge RNA and methylation subtypes by match ID
hist_mb_merged <- hist_mb_rna %>%
  left_join(hist_mb_methyl,
            by = "match_id") %>%
  dplyr::filter(!is.na(molecular_subtype_methyl)) %>%
  arrange(match_id) %>%
  distinct(match_id, molecular_subtype_rna, .keep_all = TRUE)

# print table of methylation x RNA subtypes
summary_df <- table(hist_mb_merged$dkfz_v12_methylation_subclass,
                    hist_mb_merged$molecular_subtype_rna) %>%
  as.data.frame() %>%
  pivot_wider(names_from = "Var2",
              values_from = "Freq") %>%
  dplyr::rename("Methylation Subtype" = Var1)

# write to output
write_tsv(summary_df,
          file.path(results_dir, "mb-rna-methyl-subtype-concordance.tsv"))


