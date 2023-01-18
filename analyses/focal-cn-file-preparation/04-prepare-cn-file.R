suppressPackageStartupMessages({
  library(optparse)
  library(dplyr)
  library(GenomicRanges)
  library(AnnotationDbi)
  library(org.Hs.eg.db)
  library(rtracklayer)
  library(tidyverse)
})

# This script converts a seg file into a tsv file with CN information and gene
# annotation.
#
# Code adapted from the PPTC PDX Focal Copy Number and SV Plots repository here:
# https://github.com/marislab/pptc-pdx-copy-number-and-SVs/blob/master/R/focal-CN-revision.R
#
# Chante Bethell for CCDL 2019 and Jo Lynne Rokita
#
# Modified by Komal Rathi and Run Jin for OpenPedCan 

# Get `magrittr` pipe
`%>%` <- dplyr::`%>%`

#### Command line options ------------------------------------------------------

# Declare command line options
option_list <- list(
  make_option(c("--cnv_file"), 
              type = "character", default = NULL,
              help = "file path to file that contains CNV information"),
  make_option(c("--gtf_file"), 
              type = "character", default = NULL,
              help = "file path to human genome GTF file"),
  make_option(c("--metadata"), 
              type = "character", default = NULL,
              help = "file path to histologies.tsv"),
  make_option(c("--filename_lead"), 
              type = "character", default = "annotated_cn",
              help = "used in file names"),
  make_option(c("--controlfreec"), 
              type = "logical", action = "store_true", default = FALSE,
              help = "flag used to indicate if the CNV file is the output of ControlFreeC"),
  make_option(c("--seg"), 
              type = "logical", action = "store_true", default = FALSE,
              help = "flag used to indicate if the CNV file was original a SEG file that has been prepped by a notebook to include ploidy information"),
  make_option(c("--runWXSonly"), 
              type = "logical", action = "store_true", default = FALSE,
              help = "flag used to indicate if the annotation was only ran on biospecimens with experiemntal_strategy of WXS"),
  make_option(c("--xy"), 
              type = "logical", action = "store_true", default = TRUE,
              help = "logical used to indicate if sex chromosome steps should be skipped (FALSE) or run (TRUE)")
)

# Read the arguments passed
opt_parser <- optparse::OptionParser(option_list = option_list)
opt <- optparse::parse_args(opt_parser)
cnv_file <- opt$cnv_file
gtf_file <- opt$gtf_file
metadata <- opt$metadata
filename_lead <- opt$filename_lead
controlfreec <- opt$controlfreec
seg <- opt$seg
runWXSonly <- opt$runWXSonly
xy_flag <- opt$xy

# error handling related to specifying the CNV method
if(all(controlfreec, seg)) {
  stop("--controlfreec and --seg are mutually exclusive")
}

if(!any(controlfreec, seg)) {
  stop("You must specify the CNV file format by using --controlfreec or --seg")
}

#### Directories and Files -----------------------------------------------------

# Detect the ".git" folder -- this will in the project root directory.
# Use this as the root directory to ensure proper sourcing of functions no
# matter where this is called from
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to results directory
analysis_dir <- file.path(root_dir, "analyses", "focal-cn-file-preparation")
results_dir <- file.path(analysis_dir, "results")
dir.create(results_dir, showWarnings = F, recursive = T) # identical to mkdir -p

# source function to annotate overlaps
source(file.path(analysis_dir, "util", "process_annotate_overlaps.R"))
source(file.path(analysis_dir, "util", "resolve_duplicate_annotations.R"))

#### Format CNV file and overlap with hg38 genome annotations ------------------

# we want to standardize the formats between the two methods here and drop
# columns we won't need.
if(seg){
  cnv_df <- readr::read_tsv(cnv_file) %>%
    dplyr::rename(chr = chrom, start = loc.start, end = loc.end, copy_number = copy.num) %>%
    dplyr::select(-num.mark, -seg.mean) %>%
    dplyr::select(-Kids_First_Biospecimen_ID, dplyr::everything())
}

if(controlfreec){
  # TODO: filter based on the p-values rather than just dropping them?
  cnv_df <- readr::read_tsv(cnv_file) %>%
    dplyr::rename(copy_number = copy.number) %>%
    dplyr::mutate(chr = paste0("chr", chr)) %>%
    dplyr::select(-segment_genotype, -uncertainty, -WilcoxonRankSumTestPvalue, -KolmogorovSmirnovPvalue) %>%
    dplyr::select(-Kids_First_Biospecimen_ID, dplyr::everything())
}

#### Read in metadata file -----------------------------------------------------
histologies_df <- readr::read_tsv(metadata, guess_max = 100000)

#### Subset the CNV files to contain only WXS specimens when runWXSonly parameter is set to TRUE
if(runWXSonly){
  # find WXS specimens based on histology file
  WXS_samples <- histologies_df %>% 
    dplyr::filter(experimental_strategy == "WXS") %>% 
    dplyr::pull(Kids_First_Biospecimen_ID) %>% 
    unique()
  
  # subset the cnv_df 
  cnv_df <- cnv_df %>% 
    dplyr::filter(Kids_First_Biospecimen_ID %in% WXS_samples)
}

# create an exon-based GRanges object from the input gencode annotation
# filter to exon coordinates 
gencode_gtf <- rtracklayer::import(con = gtf_file)
gencode_gtf <- gencode_gtf[gencode_gtf$type %in% "exon",]

# take distinct coordinates per gene_id, gene_name and exon_id
gencode_gtf <- gencode_gtf %>%
  as.data.frame() %>%
  dplyr::select(seqnames, start, end, gene_id, gene_name, exon_id) %>%
  dplyr::distinct() %>%
  dplyr::mutate(gene_id = gsub("\\..*", "", gene_id)) # 683694 x 6

# once distinct has been called, we don't need exon_id
gencode_gtf$exon_id <- NULL

# add cytoband info for each gene symbol and gene id combination
annotations_orgDb <- AnnotationDbi::select(org.Hs.eg.db::org.Hs.eg.db, # database
                                           keys = unique(gencode_gtf$gene_id),  # data to use for retrieval
                                           columns = c("MAP","ENSEMBL","SYMBOL"), # information to retrieve for given data
                                           keytype = "ENSEMBL")

# join using both gene name and gene id combination to avoid discrepancies, and filter to retain only one cytoband annotation per gene 
annotations_orgDb <- annotations_orgDb %>% 
  dplyr::filter(!is.na(SYMBOL)) %>%
  dplyr::rename("cytoband" = "MAP",
                "gene_id" = "ENSEMBL",
                "gene_name" = "SYMBOL")
gencode_gtf <- gencode_gtf %>%
  dplyr::inner_join(annotations_orgDb, by = c("gene_id", "gene_name")) %>%
  dplyr::distinct(seqnames, start, end, gene_id, gene_name, .keep_all = T)

# make GRanges object 
gencode_gr <- makeGRangesFromDataFrame(gencode_gtf, keep.extra.columns = TRUE)

# merge overlapping rows for each gene id
gencode_gr <- unlist(GenomicRanges::reduce(split(gencode_gr, c(gencode_gr$gene_id, gencode_gr$gene_name))))

# Create data frame of merged exon coordinates with gene id, gene name, and cytoband annotation
gencode_df <- data.frame(gencode_gr) %>%
  add_column(gene_id = names(gencode_gr)) %>%
  merge(distinct(gencode_gtf, gene_id, .keep_all = T)[,c('gene_id', 'gene_name', 'cytoband')], by = 'gene_id') %>%
  dplyr::select(seqnames, start, end, width, strand, gene_id, gene_name, cytoband)

# make GRanges object and sort by coordinates
gencode_gr <- makeGRangesFromDataFrame(gencode_df, keep.extra.columns = TRUE)
gencode_gr <- sort(gencode_gr)

#### Addressing autosomes first ------------------------------------------------
# slice the df to avoid memory exhaust issues
cnv_df_ids <- cnv_df %>% 
  dplyr::pull(Kids_First_Biospecimen_ID) %>% 
  unique()

# slice to 100 samples each
slice_vector <- seq(1, length(cnv_df_ids), 100) 

# define combined dataframe
#autosome_annotated_cn <- data.frame()
autosome_annotated_cn_resolved <- data.frame()
autosome_annotated_cn_unresolved <- data.frame()

for (i in 1:length(slice_vector)){
  start_id <- as.numeric(slice_vector[i])
  if(i<length(slice_vector)){
    end_id <- as.numeric(slice_vector[i+1]-1)
  } else {
    end_id <- as.numeric(length(cnv_df_ids))
  }
  
  # get the matching BS IDs
  cnv_df_ids_each <- cnv_df_ids[start_id:end_id]
  
  # get the matching CNV dataframe
  cnv_df_each <- cnv_df %>% 
    dplyr::filter(Kids_First_Biospecimen_ID %in% cnv_df_ids_each)
  
  # Exclude the X and Y chromosomes and some other contigs
  # Removing copy neutral segments saves on the RAM required to run this step
  # and file size
  cnv_no_xy_each <- cnv_df_each %>%
    dplyr::filter(!(chr %in% c("chrX", "chrY")),
                  !grepl("_", chr)) %>%
    distinct()
  
  # Merge and annotated no X&Y
  autosome_annotated_cn_each <- process_annotate_overlaps(cnv_df = cnv_no_xy_each, exon_granges = gencode_gr, gene_df = gencode_df) %>%
    # mark possible amplifications in autosomes
    dplyr::mutate(status = dplyr::case_when(
      copy_number > (2 * ploidy) ~ "amplification",
      copy_number == 0 ~ "deep deletion",
      TRUE ~ as.character(status)))
  
  # Resolve cases of duplicate cn calls for genes
#  autosome_annotated_cn_each <- resolve_duplicate_annotations(overlap_annotation = autosome_annotated_cn_each)
  
#  autosome_annotated_cn <- bind_rows(autosome_annotated_cn, autosome_annotated_cn_each)
  
  resolve <- resolve_duplicate_annotations(overlap_annotation = autosome_annotated_cn_each)
  
  autosome_resolved <- resolve$resolved_calls
  autosome_unresolved <- resolve$unresolved_calls
  
  autosome_annotated_cn_resolved <- bind_rows(autosome_annotated_cn_resolved, autosome_resolved)
  autosome_annotated_cn_unresolved <- bind_rows(autosome_annotated_cn_unresolved, autosome_unresolved)

}

# Output file name
if(runWXSonly){
#  autosome_output_file <- paste0(filename_lead, "_wxs_autosomes.tsv.gz")
  autosome_resolved_output_file <- paste0(filename_lead, "_wxs_autosomes.tsv.gz")
  autosome_unresolved_output_file <- paste0(filename_lead, "_wxs_autosomes_unresolved.tsv.gz")
} else {
#  autosome_output_file <- paste0(filename_lead, "_autosomes.tsv.gz")
  autosome_resolved_output_file <- paste0(filename_lead, "_autosomes.tsv.gz")
  autosome_unresolved_output_file <- paste0(filename_lead, "_autosomes_unresolved.tsv.gz")
}

# Save final data.frame to a tsv file
#readr::write_tsv(autosome_annotated_cn, file.path(results_dir, autosome_output_file))
readr::write_tsv(autosome_annotated_cn_resolved, file.path(results_dir, autosome_resolved_output_file))
readr::write_tsv(autosome_annotated_cn_unresolved, file.path(results_dir, autosome_unresolved_output_file))


#### X&Y -----------------------------------------------------------------------

if(xy_flag){
  # define combined dataframe
  #sex_chrom_annotated_cn <- data.frame()
  sex_chrom_annotated_cn_resolved <- data.frame()
  sex_chrom_annotated_cn_unresolved <- data.frame()
  for (j in 1:length(slice_vector)){
    start_id <- as.numeric(slice_vector[j])
    if(j<length(slice_vector)){
      end_id <- as.numeric(slice_vector[j+1]-1)
    } else {
      end_id <- as.numeric(length(cnv_df_ids))
    }
    
    # get the matching BS IDs
    cnv_df_ids_each <- cnv_df_ids[start_id:end_id]
    
    # get the matching CNV dataframe
    cnv_df_each <- cnv_df %>% 
      dplyr::filter(Kids_First_Biospecimen_ID %in% cnv_df_ids_each)
    
    # Filter to just the X and Y chromosomes and remove neutral segments
    # Removing copy neutral segments saves on the RAM required to run this step
    # and file size
    cnv_sex_chrom_each <- cnv_df_each %>%
      dplyr::filter(chr %in% c("chrX", "chrY"))
    
    # Merge and annotated X&Y
    sex_chrom_annotated_cn_each <- process_annotate_overlaps(cnv_df = cnv_sex_chrom_each, exon_granges = gencode_gr, gene_df = gencode_df) %>%
      # mark possible deep loss in sex chromosome
      dplyr::mutate(status = dplyr::case_when(
        copy_number == 0  ~ "deep deletion",
        TRUE ~ as.character(status))
      )
    
    # Resolve cases of duplicate cn calls for genes
    #sex_chrom_annotated_cn_each <- resolve_duplicate_annotations(overlap_annotation = sex_chrom_annotated_cn_each)
    
    resolve <- resolve_duplicate_annotations(overlap_annotation = sex_chrom_annotated_cn_each)
    
    sex_chrom_resolved <- resolve$resolved_calls
    sex_chrom_unresolved <- resolve$unresolved_calls
    
    # Add germline sex estimate into this data.frame
    #sex_chrom_annotated_cn_each <- sex_chrom_annotated_cn_each %>%
    #  dplyr::inner_join(dplyr::select(histologies_df,
    #                                  Kids_First_Biospecimen_ID,
    #                                  germline_sex_estimate),
    #                    by = c("biospecimen_id" = "Kids_First_Biospecimen_ID")) %>%
    #  dplyr::select(-germline_sex_estimate, dplyr::everything())
    
     #Add germline sex estimate into this data.frame
     sex_chrom_resolved <- sex_chrom_resolved %>%
      dplyr::inner_join(dplyr::select(histologies_df,
                                      Kids_First_Biospecimen_ID,
                                      germline_sex_estimate),
                        by = c("biospecimen_id" = "Kids_First_Biospecimen_ID")) %>%
      dplyr::select(-germline_sex_estimate, dplyr::everything())
     
     sex_chrom_unresolved <- sex_chrom_unresolved %>%
       dplyr::inner_join(dplyr::select(histologies_df,
                                       Kids_First_Biospecimen_ID,
                                       germline_sex_estimate),
                         by = c("biospecimen_id" = "Kids_First_Biospecimen_ID")) %>%
       dplyr::select(-germline_sex_estimate, dplyr::everything())
    
    # combine the results
    #sex_chrom_annotated_cn <- bind_rows(sex_chrom_annotated_cn, sex_chrom_annotated_cn_each)
    
    sex_chrom_annotated_cn_resolved <- bind_rows(sex_chrom_annotated_cn_resolved, sex_chrom_resolved)
    sex_chrom_annotated_cn_unresolved <- bind_rows(sex_chrom_annotated_cn_unresolved, sex_chrom_unresolved)
    
  }
  
  # Output file name
  if(runWXSonly){
#    sex_chrom_output_file <- paste0(filename_lead, "_wxs_x_and_y.tsv.gz")
    sex_chrom_resolved_output_file <- paste0(filename_lead, "_wxs_x_and_y.tsv.gz")
    sex_chrom_unresolved_output_file <- paste0(filename_lead, "_wxs_x_and_y_unresolved.tsv.gz")
  } else {
#    sex_chrom_output_file <- paste0(filename_lead, "_x_and_y.tsv.gz")
    sex_chrom_resolved_output_file <- paste0(filename_lead, "_x_and_y.tsv.gz")
    sex_chrom_unresolved_output_file <- paste0(filename_lead, "_x_and_y_unresolved.tsv.gz")
  }
  
  # Save final data.frame to a tsv file
#  readr::write_tsv(sex_chrom_annotated_cn, file.path(results_dir, sex_chrom_output_file))
  readr::write_tsv(sex_chrom_annotated_cn_resolved, file.path(results_dir, sex_chrom_resolved_output_file))
  readr::write_tsv(sex_chrom_annotated_cn_unresolved, file.path(results_dir, sex_chrom_unresolved_output_file))
}
