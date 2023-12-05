# Reformat GENCODE gene features and Illumina infinium methylation array CpG 
# probe coordinates Human Build 38 (GRCh38/hg38) liftover bedtools intersect 

# Eric Wafula for Pediatric OpenTargets
# 06/26/2023

# Load libraries
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tidyverse))

# set up optparse options
option_list <- list(
  make_option(opt_str = "--bed_intersect", type = "character", default = NULL,
              help = "GENCODE gene fetures and CpG liftover intersect bed file",
              metavar = "character")
)

# parse parameter options
opt <- parse_args(OptionParser(option_list = option_list))
bed_intersect <- opt$bed_intersect

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set module and results directory
module_dir <- file.path(root_dir, "analyses", "methylation-probe-annotations")
results_dir <- file.path(module_dir, "results")


# Parse bedtools GENCODE gene fetures and CpG liftover intersect bed file

readr::read_tsv(
  file.path(results_dir, 
            "infinium.gencode.v39.probe.annotations.bedtools.tsv.gz"), 
  col_names = FALSE) |> 
  dplyr::select(X1, X2, X4, X8, X6, X7, X9, X10, X11, X12) |>
  dplyr::rename(Chromosome = X1, Location = X2, Probe_ID = X4, 
                Gene_Feature = X8, Start = X6, End = X7, Strand = X9, 
                transcript_id = X10, targetFromSourceId = X11, 
                Gene_symbol = X12) |> 
  dplyr::distinct() |> 
  dplyr::arrange(Chromosome, Location) |>
  dplyr::mutate(Gene_Feature = case_when(Gene_Feature == "." ~ "intergenic", 
                                         TRUE ~ Gene_Feature), 
                Start = case_when(Start == -1 ~ NA_integer_, 
                                  TRUE ~ as.integer(Start)), 
                End = case_when(End == -1 ~ NA_integer_, 
                                TRUE ~ as.integer(End)), 
                Strand = case_when(Strand == "." ~ NA_character_, 
                                   TRUE ~ Strand), 
                transcript_id = case_when(transcript_id == "." ~ NA_character_,
                                          TRUE ~ transcript_id), 
                targetFromSourceId = case_when(targetFromSourceId == "." ~ NA_character_, 
                                               TRUE ~ targetFromSourceId), 
                Gene_symbol = case_when(Gene_symbol == "." ~ NA_character_, 
                                        TRUE ~ Gene_symbol)) |> 
  readr::write_tsv(
    file.path(results_dir, "infinium.gencode.v39.probe.annotations.tsv.gz"))
