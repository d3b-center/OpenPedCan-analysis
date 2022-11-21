# J. Taroni for CCDL 2019
# Updated by Eric Wafula for Pediatric Open Targets 2022
# This script is the second step in generating subset files for continous
# integration. It takes the output of 01-get_biospecimen_identifiers.R and
# subsets the OpenPedCan files and writes the new subset files to a 
# user-specified directory.
#
# EXAMPLE USAGE:
#   Rscript analyses/create-subset-files/02-subset_files.R \
#     --biospecimen_file analyses/create-subset-files/biospecimen_ids_for_subset.RDS \
#     --output_directory data/testing/v11

#### Libraries and functions ---------------------------------------------------

suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(options(readr.show_col_types = FALSE))


write_maf_file <- function(maf_df, file_name, version_string) {
  # Given a data.frame that contains the fields for a MAF file, write a gzipped
  # MAF file and include the version information provided in version_string.
  #
  # Note: if file_name exists, it will be overwritten
  #
  # Args:
  #   maf_df: A data.frame that contains the MAF info.
  #   file_name: Output file name, including the full path.
  #   version_string: the version string that will be written to the first line
  #                   of the file at file_name
  #
  # Returns: intended to be used to write files only

  # if the file name supplied to this function ends in `.gz`, take it out for
  # the purposes of writeLines, etc.
  # we'll gzip it at the end with R.utils::gzip and this extension is not needed
  if (grepl(".gz", file_name)) {
    file_name <- sub(".gz", "", file_name)
  }

  # write the version string to the top of the file
  writeLines(version_string, con = file_name)

  # write the tabular data of maf_df
  readr::write_tsv(maf_df, path = file_name, append = TRUE, col_names = TRUE)

  # now gzip the file
  R.utils::gzip(file_name, overwrite = TRUE)
}

subset_files <- function(filename, biospecimen_ids, output_directory) {
  # given the full path to a file to be subset and the list of biospecimen ids
  # to use for subsetting, write a file of the same name to the output directory
  # that has been subset using the IDs
  #
  # Args:
  #   filename: full path to file to be subset
  #   biospecimen_ids: vector of identifiers to use for subsetting the file
  #   output_directory: directory to write the subset file to
  #
  # Returns: writes a subset file to output_directory

  `%>%` <- dplyr::`%>%`

  message(paste("Reading in and subsetting", filename, "..."))

  # the filename argument contains path information for the file we're reading
  # *in* -- we need to conserve the file name itself but change the path for
  # *output*
  output_file <- sub(paste0(".*", .Platform$file.sep), "", filename)
  output_file <- file.path(output_directory, output_file)

  # filtering strategy depends on the file type, mostly because how the sample
  # IDs change based on the file type -- that's why this logic is required
  if (grepl("snv", filename)) {
    if (grepl("hotspots", filename)) {
      snv_file <- data.table::fread(filename,
                                    skip = 1,  # skip version string
                                    data.table = FALSE,
                                    showProgress = FALSE)
      # we need to obtain the version string from the first line of the MAF file
      version_string <- readLines(filename, n = 1)
      # filter + write to file with custom function
      snv_file %>%
        dplyr::filter(Tumor_Sample_Barcode %in% biospecimen_ids) %>%
        write_maf_file(file_name = output_file,
                       version_string = version_string)
      snv_file %>%
        dplyr::filter(Tumor_Sample_Barcode %in% biospecimen_ids) %>%
        readr::write_tsv(output_file)
    } else {
      # in a column 'Tumor_Sample_Barcode'
      snv_file <- data.table::fread(filename, data.table = FALSE, 
                                    showProgress = FALSE)
      snv_file %>%
        dplyr::filter(Tumor_Sample_Barcode %in% biospecimen_ids) %>%
        readr::write_tsv(output_file)
    }
  } else if (grepl("biospecimen", filename)) {
    # in a column 'Kids_First_Biospecimen_ID'
    bed_file <- readr::read_tsv(filename)
    bed_file %>% 
      dplyr::filter(Kids_First_Biospecimen_ID %in% biospecimen_ids) %>%
      readr::write_tsv(output_file)
  } else if (grepl("cnv", filename)) {
    # in a column 'ID', 'Kids_First_Biospecimen_ID', and 'biospecimen_id'
    cnv_file <- readr::read_tsv(filename)
    biospecimen_column <- 
      intersect(colnames(cnv_file), 
                c("ID", "Kids_First_Biospecimen_ID", "biospecimen_id"))
    cnv_file %>%
      dplyr::filter(!!rlang::sym(biospecimen_column) %in% biospecimen_ids) %>%
      readr::write_tsv(output_file)
  } else if (grepl("consensus_seg_with_status", filename)) {
    # in a column Kids_First_Biospecimen_ID',
    cn_seg_status_file <- readr::read_tsv(filename)
    cn_seg_status_file %>%
      dplyr::filter(Kids_First_Biospecimen_ID %in% biospecimen_ids) %>%
      readr::write_tsv(output_file)
  } else if (grepl("fusion", filename)) {
    fusion_file <- readr::read_tsv(filename)
    # original files contain the biospecimen IDs in a column called 'tumor_id',
    # the filtered/prioritized list biospecimen IDs are in 'Sample'
    if (grepl("putative-oncogenic", filename)) {
      fusion_file %>%
        dplyr::filter(Sample %in% biospecimen_ids |
                        # this is required for the the fusion-summary module
                        grepl("RELA|MN1|EWSR1|FGFR1--TACC1|MYB--QKI|BRAF", FusionName)) %>%
        readr::write_tsv(output_file)
    } else if (grepl("dgd", filename)) {
      fusion_file %>%
        dplyr::filter(Tumor_Sample_Barcode %in% biospecimen_ids) %>%
        readr::write_tsv(output_file)
    } else if (grepl("fusion_summary", filename)) {
      fusion_file %>%
        dplyr::filter(Kids_First_Biospecimen_ID %in% biospecimen_ids) %>%
        readr::write_tsv(output_file)
    } else {
      fusion_file %>%
        dplyr::filter(tumor_id %in% biospecimen_ids) %>%
        readr::write_tsv(output_file)
    }
  } else if (grepl("sv-manta", filename)) {
    # in a column 'Kids.First.Biospecimen.ID.Tumor'
    sv_file <- data.table::fread(filename, data.table = FALSE, 
                                 showProgress = FALSE)
    sv_file %>%
      dplyr::filter(Kids.First.Biospecimen.ID.Tumor %in% biospecimen_ids) %>%
      readr::write_tsv(output_file)
  } else if (grepl(".rds", filename)) {
    # RNA-Seq matrices column names
    expression_file <- readr::read_rds(filename)
    # because we're selecting columns, we have to include this steps
    biospecimen_ids <- intersect(colnames(expression_file), biospecimen_ids)
    if (grepl("rna-isoform", filename)) {
      expression_file %>% dplyr::select(transcript_id, gene_symbol,
                                        all_of(!!!rlang::quos(biospecimen_ids))) %>% 
        readr::write_rds(output_file)
    } else {
      expression_file %>% dplyr::select(all_of(!!!rlang::quos(biospecimen_ids))) %>% 
        readr::write_rds(output_file)
    }
  } else if (grepl("independent", filename)) {
    # in a column 'Kids_First_Biospecimen_ID'
    independent_file <- readr::read_tsv(filename)
    independent_file %>% 
      dplyr::filter(Kids_First_Biospecimen_ID %in% biospecimen_ids) %>%
      readr::write_tsv(output_file)
  } else {
    # error-handling
    stop("File type unrecognized by 'subset_files'")
  }
}

#### command line arguments ----------------------------------------------------

option_list <- list(
  make_option(
    c("-i", "--biospecimen_file"),
    type = "character",
    default = NULL,
    help = "full path to RDS file that contains a list of biospecimen IDs",
  ),
  make_option(
    c("-o", "--output_directory"),
    type = "character",
    default = NULL,
    help = "output directory for subset files"
  )
)

# Read the arguments passed
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

#### subset the files ----------------------------------------------------------

# read in list of biospecimen idefinters
biospecimen_ids_list <- readr::read_rds(opt$biospecimen_file)

output_directory <- opt$output_directory
if (!dir.exists(output_directory)) {
  dir.create(output_directory, recursive = TRUE)
}

# create a list from the names of the biospecimen_ids_list
# this will correspond to the filenames
filename_list <- as.list(names(biospecimen_ids_list))

# "loop" through the files to create subset files
invisible(purrr::map2(filename_list, biospecimen_ids_list,
            ~ subset_files(filename = .x,
                           biospecimen_ids = .y,
                           output_directory = output_directory))
)

