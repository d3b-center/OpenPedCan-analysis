# Create GENCODE gene features and Illumina infinium methylation array CpG 
# probe coordinates bed files

# Eric Wafula for Pediatric OpenTargets
# 06/26/2023

# Load libraries
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(rtracklayer))
suppressPackageStartupMessages(library(tidyverse))

# set up optparse options
option_list <- list(
  make_option(opt_str = "--gencode_gtf", type = "character", default = NULL,
              help = "GENCODE GTF",
              metavar = "character"),
  make_option(opt_str = "--gencode_gff", type = "character", default = NULL,
              help = "GENCODE GFF with intron coordinates",
              metavar = "character"),
  make_option(opt_str = "--cpg_map", type = "character", default = NULL,
              help = "Illumina infinium methylation array CpG probe coordinates",
              metavar = "character")
)

# parse parameter options
opt <- parse_args(OptionParser(option_list = option_list))
gencode_gtf <- opt$gencode_gtf
gencode_gff <- opt$gencode_gff
cpg_map <- opt$cpg_map

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set module and inputs directory
module_dir <- file.path(root_dir, "analyses", "methylation-probe-annotations")
inputs_dir <- file.path(module_dir, "inputs")

# create gene to transcript from gencode gtf
gene_transcript_map <- rtracklayer::import(con = gencode_gtf) |> 
  tibble::as_tibble() |> 
  dplyr::select(gene_id, transcript_id, gene_name) |>
  tidyr::drop_na() |>
  dplyr::mutate(transcript_id = stringr::str_extract(transcript_id, "ENST\\d+"), 
                gene_id = stringr::str_extract(gene_id, "ENSG\\d+")) |> 
  dplyr::distinct()
  
# load gencode gff with intron coordinates and covert to bed format or selected
# nuclear chromosome gene features - exon, intron, five_prime_UTR, and 
# three_prime_UTR
gencode_bed <- rtracklayer::readGFF(gencode_gff) |>
  tibble::as_tibble() |>
  dplyr::filter(type %in% c("exon", "intron",
                            "five_prime_UTR", "three_prime_UTR"),
                !grepl("^chrM|^GL|^KI", seqid)) |>
  dplyr::select(seqid, start, end, type, Parent, strand) |>
  dplyr::rename(transcript = Parent) |>
  dplyr::mutate(seqid = as.character(seqid),
                type = as.character(type),
                transcript = as.character(transcript),
                transcript = stringr::str_extract(transcript, "\\w+")) |>
  dplyr::distinct()

# filter gene features bed to retain only the most terminal 3'-UTRs and 5'-UTRs 
# where multiple UTRs have been predicted for a transcript
exons_introns <- gencode_bed |> 
  dplyr::filter(!type %in% c("five_prime_UTR", "three_prime_UTR"))
plus_five_utrs <-gencode_bed |> 
  dplyr::filter(type == "five_prime_UTR", strand == "+") |> 
  dplyr::group_by(seqid, type, transcript, strand) |> 
  dplyr::summarize(start = min(start), end = min(end)) |> 
  dplyr::arrange(seqid, start, end) |> 
  ungroup()
minus_five_utrs <-gencode_bed |> 
  dplyr::filter(type == "five_prime_UTR", strand == "-") |> 
  dplyr::group_by(seqid, type, transcript, strand) |> 
  dplyr::summarize(start = min(start), end = min(end)) |> 
  dplyr::arrange(seqid, start, end) |> 
  ungroup()
plus_three_utrs <-gencode_bed |> 
  dplyr::filter(type == "three_prime_UTR", strand == "+") |> 
  dplyr::group_by(seqid, type, transcript, strand) |> 
  dplyr::summarize(start = min(start), end = min(end)) |> 
  dplyr::arrange(seqid, start, end) |> 
  ungroup()
minus_three_utrs <-gencode_bed |> 
  dplyr::filter(type == "three_prime_UTR", strand == "-") |> 
  dplyr::group_by(seqid, type, transcript, strand) |> 
  dplyr::summarize(start = min(start), end = min(end)) |> 
  dplyr::arrange(seqid, start, end) |> 
  ungroup()
gencode_bed <- dplyr::bind_rows(exons_introns, plus_five_utrs, minus_five_utrs,
                                plus_three_utrs, minus_three_utrs) |> 
  dplyr::select(seqid, start, end, type, strand, transcript) |> 
  dplyr::arrange(seqid, start, end, transcript) |> 
  dplyr::distinct() 

# # extend 3'-UTR by 1kb
# gencode_bed <- gencode_bed |>
#   dplyr::mutate(start = case_when(type == "three_prime_UTR" &
#                                     strand == "-" ~ as.integer(start - 1000),
#                                   TRUE ~ as.integer(start)),
#                 end = case_when(type == "three_prime_UTR" &
#                                   strand == "+" ~ as.integer(end + 1000),
#                                 TRUE ~ as.integer(end)))


# add three_prime_UTR_extension - 1kb extension beyond the 3'-UTR
three_prime_UTR_extensions <- gencode_bed |>
  dplyr::filter(type == "three_prime_UTR") |>
  dplyr::mutate(type = "three_prime_UTR_extension",
                start = case_when(strand == "-" ~ as.integer(start - 1001), 
                                  strand == "+" ~  as.integer(end + 1)),
                end = case_when(strand == "-" ~ as.integer(start + 1000),
                                strand == "+" ~ as.integer(end + 1001)))


# add promoter region - 1kb extension beyond the 5'-UTR
promoters <- gencode_bed |>
  dplyr::filter(type == "five_prime_UTR") |>
  dplyr::mutate(type = "promoter",
                start = case_when(strand == "-" ~ as.integer(end + 1), 
                                  strand == "+" ~  as.integer(start - 1001)),
                end = case_when(strand == "-" ~ as.integer(end + 1001),
                                strand == "+" ~ as.integer(start + 1000)))

# merge promoters to all other features
gencode_features_bed <- gencode_bed |> 
  dplyr::bind_rows(promoters) |>
  dplyr::bind_rows(three_prime_UTR_extensions) |>
  dplyr::mutate(start = case_when(start < 1 ~ as.integer(1),
                                  TRUE ~ as.integer(start)),
                end = case_when(end < 1 ~ as.integer(1),
                                TRUE ~ as.integer(end))) |> 
  dplyr::arrange(seqid, start, end, transcript) |>
  dplyr::rename(transcript_id = transcript) |>
  # dplyr::rename(Chromosome = seqid, Start = start, End = end, Strand = strand, 
  #               Gene_Feature = type, transcript_id = transcript) |>
  dplyr::left_join(gene_transcript_map, by = "transcript_id") |>
  dplyr::distinct()

# write gencode gene features bed format to file
gencode_features_bed |> 
  readr::write_tsv(
    file.path(inputs_dir, 
              "gencode.v39.primary_assembly.gene_features.annotation.bed"),
    col_names = FALSE)

# write methylation array CpG probe coordinates to bed format to file
readr::read_csv(cpg_map, skip = 7) |> 
  dplyr::select(CHR, MAPINFO, Name) |> 
  dplyr::mutate(MAPINFO2 = MAPINFO) |>
  dplyr::select(CHR, MAPINFO, MAPINFO2, Name) |>
  tidyr::drop_na() |>
  dplyr::mutate(CHR = paste0("chr", CHR)) |>
  dplyr::arrange(CHR, MAPINFO) |>
  dplyr::distinct() |>
  readr::write_tsv(
    file.path(inputs_dir,
              "infinium-methylationepic-v-1-0-b5-manifest-file-grch37.bed"),
    col_names = FALSE)
