# Calculate TMB for a given SNV consensus MAF file from Strelka2, Mutect2,
# Vardict, data Lancet callers
#
# Eric Wafula for Pediatric OpenTargets
# 12/10/2021
# Adapted from AlexsLemonade OpenPBTA-analysis snv-callers analysis module
#

# Load libraries:
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(GenomicRanges))
suppressPackageStartupMessages(library(tmb))

# set up optparse options
option_list <- list(
  make_option(
    opt_str = "--consensus_maf_file", type = "character", default = NULL,
    help = "Input OpenPedCan SNV consensus consensus MAF file.",
    metavar = "character"
  ),
  make_option(
    opt_str = "--bed_files", type = "character", default = NULL,
    help = "Input samples to target BED mapping file."
  ),
  make_option(
    opt_str = "--histologies_file", type = "character", default = NULL,
    help = "Input OpenPedCan histologies metadata file.",
    metavar = "character"
  ),
  make_option(
    opt_str = "--coding_regions", type = "character",
    help = "BED file for coding regions to use for coding only TMB.",
    metavar = "character"
  ),
  make_option(
    opt_str = "--nonsynfilter_maf", action = "store_true", default = FALSE,
    help = "If TRUE, filter out synonymous mutations, keep
              non-synonymous mutations, according to maftools definition.
              Default is FALSE",
    metavar = "character"
  ),
  make_option(
    opt_str = "--nonsynfilter_focr", action = "store_true", default = FALSE,
    help = "If TRUE, filter out synonymous mutations, keep
              non-synonymous mutations, according to Friends of Cancer
              Research definition. Default is FALSE",
    metavar = "character"
  )
)

# parse parameter options
opt <- parse_args(OptionParser(option_list = option_list))
consensus_maf_file <- opt$consensus_maf_file
bed_files <- opt$bed_files
histologies_file <- opt$histologies_file
coding_regions <- opt$coding_regions
nonsynfilter_maf <- opt$nonsynfilter_maf
nonsynfilter_focr <- opt$nonsynfilter_focr

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to data, module and results directories
data_dir <- file.path(root_dir, "data")
module_dir <- file.path(root_dir, "analyses", "tmb-calculation")
results_dir <- file.path(module_dir, "results")
input_dir <- file.path(module_dir, "input")

# Create results folder if it doesn't exist
if (!dir.exists(results_dir)) {
  dir.create(results_dir)
}

# output file based on data_name
tmb_coding_file <- file.path(results_dir, "snv-mutation-tmb-coding.tsv")
tmb_all_file <- file.path(results_dir, "snv-mutation-tmb-all.tsv")

############################ Obtain caller mutations ###########################
message("Laoding input mutation file...\n")

# select required columns to reduce memory requirements
required_cols <- c(
  "Chromosome",
  "Start_Position",
  "End_Position",
  "Variant_Type",
  "Reference_Allele",
  "Allele",
  "Tumor_Seq_Allele1",
  "Tumor_Seq_Allele2",
  "Match_Norm_Seq_Allele1",
  "Match_Norm_Seq_Allele2",
  "Tumor_Sample_Barcode",
  "Variant_Classification",
  "t_depth",
  "t_alt_count",
  "t_ref_count"
)

# read consensus maf file
consensus_maf_df <- readr::read_delim(consensus_maf_file, comment = "#", delim = "\t") %>%
  select(required_cols) %>%
  dplyr::mutate(vaf = (t_alt_count / (t_ref_count + t_alt_count)))

message("Spliting MNV calls and merging with SNV calls...\n")

# variant classification with high/moderate variant consequences from maftools
maf_nonsynonymous <- c(
  "Missense_Mutation",
  "Frame_Shift_Del",
  "In_Frame_Ins",
  "Frame_Shift_Ins",
  "Splice_Site",
  "Nonsense_Mutation",
  "In_Frame_Del",
  "Nonstop_Mutation",
  "Translation_Start_Site"
)

focr_nonsynonymous <- c(
  "Missense_Mutation",
  "Frame_Shift_Del",
  "In_Frame_Ins",
  "Frame_Shift_Ins",
  "Nonsense_Mutation",
  "In_Frame_Del"
)

# variant filters
vaf_cutoff <- 0.05
var_count <- 3
tumor_depth <- 25

# filter create the consensus MAF for SNV calls (non-MNV)
snv_maf_df <- consensus_maf_df %>%
  dplyr::filter(!Variant_Type %in% c("DNP", "TNP", "ONP"))

# get MNV calls from the consensus MAF file and split into SNV calls
split_mnv_maf_df <- split_mnv(consensus_maf_df) %>%
  dplyr::select(-c(mnv_id, mnv_pos))

# Merge SNV calls with split MNV calls
snv_mnv_maf_df <- rbind(snv_maf_df, split_mnv_maf_df) %>%
  distinct(Chromosome, Start_Position, Reference_Allele, Allele,
    Tumor_Sample_Barcode,
    .keep_all = TRUE
  )

# If the maftools non-synonymous filter is on, filter out synonymous mutations
if (nonsynfilter_maf) {
  snv_mnv_maf_df <- snv_mnv_maf_df %>%
    dplyr::filter(
      Variant_Classification %in% maf_nonsynonymous,
      t_depth >= tumor_depth,
      vaf >= vaf_cutoff,
      t_alt_count >= var_count
    )
}

# If the FoCR non-synonymous filter is on, filter out synonymous mutations
# according to that definition
if (nonsynfilter_focr) {
  snv_mnv_maf_df <- snv_mnv_maf_df %>%
    dplyr::filter(
      Variant_Classification %in% focr_nonsynonymous,
      t_depth >= tumor_depth,
      vaf >= vaf_cutoff,
      t_alt_count >= var_count
    )
}

########################### Set up metadata columns ############################
message("Setting up metadata...\n")

# load samples to target BED mapping file
bed_df <- readr::read_tsv(bed_files)
# assert all sample ids are not NA
stopifnot(identical(
  sum(is.na(bed_df$Kids_First_Biospecimen_ID)),
  as.integer(0)
))
# assert all sample ids are unique
stopifnot(identical(
  length(bed_df$Kids_First_Biospecimen_ID),
  length(unique(bed_df$Kids_First_Biospecimen_ID))
))
# load histologies file
hist_df <- readr::read_tsv(histologies_file, guess_max = 10000)

# merge samples to target BED mapping file with select metadata from
# histologies file
metadata_df <- bed_df %>%
  dplyr::inner_join(hist_df %>%
    dplyr::select(
      Kids_First_Biospecimen_ID,
      experimental_strategy
    ),
  by = "Kids_First_Biospecimen_ID"
  ) %>%
  dplyr::rename(
    Tumor_Sample_Barcode = Kids_First_Biospecimen_ID,
    target_bed = bed_to_use
  )

# Isolate metadata to only the samples that are in the mutation dataset
metadata_df <- metadata_df %>% dplyr::filter(
  Tumor_Sample_Barcode %in% unique(snv_mnv_maf_df$Tumor_Sample_Barcode)
) %>%
  # Make a Target BED regions file path column
  # dplyr::mutate(target_bed_path =  file.path(input_dir, target_bed)) %>%
  dplyr::mutate(
    target_bed_path =
      dplyr::recode(target_bed,
        "intersect_strelka_mutect2_vardict_WGS.bed" =
          file.path(root_dir, "scratch/intersect_strelka_mutect2_vardict_WGS.bed"),
        .default = file.path(data_dir, target_bed)
      )
  )

# exclude samples in that are in the mutation dataset and not the metadata
# ideally this should not happen but is currently the case in the v10
# mutation dataset
snv_mnv_maf_df <- snv_mnv_maf_df %>%
  dplyr::filter(Tumor_Sample_Barcode %in% metadata_df$Tumor_Sample_Barcode)

# Add in metadata
snv_mnv_maf_df <- snv_mnv_maf_df %>%
  dplyr::inner_join(metadata_df %>%
    dplyr::select(
      Tumor_Sample_Barcode,
      experimental_strategy,
      target_bed,
      target_bed_path
    ),
  by = "Tumor_Sample_Barcode"
  ) %>%
  # Remove samples if they are not WGS or WXS
  dplyr::filter(experimental_strategy %in% c("WGS", "WXS", "Targeted Sequencing"))

########################## Set Up overall BED Files ############################
message("Setting up overall BED ranges...\n")

# Make a data.frame of the unique BED file paths and their names
bed_files_key_df <- metadata_df %>%
  dplyr::select(Tumor_Sample_Barcode, target_bed, target_bed_path) %>%
  dplyr::distinct()

# Get the file paths for the bed files
bed_file_paths <- bed_files_key_df %>%
  dplyr::distinct(target_bed, target_bed_path) %>%
  tibble::deframe()

# Read in each unique BED file and turn into GenomicRanges object
bed_ranges_list <- lapply(bed_file_paths, function(bed_file) {

  # Read in BED file as data.frame
  bed_df <- readr::read_tsv(bed_file,
    col_names = c("chr", "start", "end")
  )

  # Make into a GenomicRanges object
  bed_ranges <- GenomicRanges::GRanges(
    seqnames = bed_df$chr,
    ranges = IRanges::IRanges(
      start = bed_df$start,
      end = bed_df$end
    )
  )
  return(bed_ranges)
})

#################### Set up Coding Region version of BED ranges ################
message("Setting up coding regions BED ranges...\n")

# Read in the coding regions BED file
coding_regions_df <- readr::read_tsv(coding_regions,
  col_names = c("chr", "start", "end")
)

# Make into a GenomicRanges object
coding_ranges <- GenomicRanges::GRanges(
  seqnames = coding_regions_df$chr,
  ranges = IRanges::IRanges(
    start = coding_regions_df$start,
    end = coding_regions_df$end
  )
)

# For each BED range, find the coding regions intersection
coding_bed_ranges_list <- lapply(bed_ranges_list, function(bed_range,
                                                           coding_grange = coding_ranges) {
  # Find the intersection
  # prints warnings of sequences sequence not genomics and coding ranges
  # warnings suppressed
  coding_intersect_ranges <- suppressWarnings(
    GenomicRanges::intersect(bed_range, coding_grange)
  )

  # Return the reduce version of these ranges
  return(GenomicRanges::reduce(coding_intersect_ranges))
})

########################### All mutations TMB file #############################
message("Calcultating overall TMB...\n")

# Run TMB calculation on each tumor sample and its respective BED range
tmb_all_df <- purrr::map2_df(
  bed_files_key_df$Tumor_Sample_Barcode,
  bed_files_key_df$target_bed,
  ~ calculate_tmb(
    tumor_sample_barcode = .x,
    maf_df = snv_mnv_maf_df,
    bed_ranges = bed_ranges_list[[.y]]
  )
)

# Write to TSV file
readr::write_tsv(tmb_all_df, tmb_all_file)

# Print out completion message
message(paste("TMB 'all' calculations saved to:\n", tmb_all_file))
############################# Coding TMB file ##################################
message(paste("\nCalculating coding only TMB...\n"))

# Run coding TMB calculation on each tumor sample and its
# respective coding BED range
tmb_coding_df <- purrr::map2_df(
  bed_files_key_df$Tumor_Sample_Barcode,
  bed_files_key_df$target_bed,
  ~ calculate_tmb(
    tumor_sample_barcode = .x,
    maf_df = snv_mnv_maf_df,
    bed_ranges = coding_bed_ranges_list[[.y]]
  )
)

# Write to TSV file
readr::write_tsv(tmb_coding_df, tmb_coding_file)

# Print out completion message
message(paste("TMB 'coding only' calculations saved to:\n", tmb_coding_file, "\n"))
