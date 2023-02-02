# Create Pediatric OpenTargets methylation summary table that will be utilized
# with OPenPedCan plotting API and displayed on the NCI MTP portal

# Eric Wafula for Pediatric OpenTargets
# 10/22/2022

# Load libraries
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(dbplyr))
suppressPackageStartupMessages(library(DBI))
suppressPackageStartupMessages(library(RSQLite))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(ids))

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# set up optparse options
option_list <- list(
  make_option(opt_str = "--methyl_tpm_corr", type = "character", default = NULL,
              help = "Methyl beta/m-vlaues to tpm-values correlations results file",  
              metavar = "character"),
  make_option(opt_str = "--methyl_probe_qtiles", type = "character", default = NULL,
              help = "Methyl array probe beta/m-values quantiles results file",
              metavar = "character"),
  make_option(opt_str = "--methyl_probe_annot", type = "character", default = NULL,
              help = "Methyl gencode array probe annotation results file",
              metavar = "character"),
  make_option(opt_str = "--efo_mondo_annot", type = "character", default =  NULL,
              help = "OpenPedCan EFO and MONDO annotation file", 
              metavar = "character"),
  make_option(opt_str = "--exp_values", type = "character", default = "gene",
              help = "OpenPedCan expression matrix values: gene (default) and isoform", 
              metavar = "character"),
  make_option(opt_str = "--methyl_values", type = "character", default = "beta",
              help = "OpenPedCan methly matrix values: beta (default) and m", 
              metavar = "character"),
  make_option(opt_str = "--tpm_transcript_rep", type = "character", default = NULL,
              help = "RNA-Seq expression (tpm) gene isoform (transcript) representation results file",
              metavar = "character")
)

# parse parameter options
opt <- parse_args(OptionParser(option_list = option_list))
methyl_tpm_corr <- opt$methyl_tpm_corr
methyl_probe_qtiles <- opt$methyl_probe_qtiles
methyl_probe_annot <- opt$methyl_probe_annot
efo_mondo_annot <- opt$efo_mondo_annot
exp_values <- opt$exp_values
methyl_values <- opt$methyl_values
tpm_transcript_rep <- opt$tpm_transcript_rep

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module and results directories
data_dir <- file.path(root_dir, "data")
analyses_dir <- file.path(root_dir, "analyses")
module_dir <- file.path(root_dir, "analyses", "methylation-summary")
results_dir <- file.path(module_dir, "results")

# Creating Pediatric OpenTargets methylation summary table
message("==========================================================")
message("Creating Pediatric OpenTargets methyl summary table")
message("==========================================================\n")

# using on-disk RSQLite database for to join tables; dplyr requires utilizes
# lots memory for large table joins.
db_connect <- DBI::dbConnect(RSQLite::SQLite(), path = "")

# load methyl beta/m-values array probe quantiles
message("--Loading probe-level quantiles...\n")
DBI::dbWriteTable(db_connect, "methyl_probe_qtiles_tb",
                  data.table::fread(methyl_probe_qtiles, showProgress = FALSE))

# load methyl beta/m-values to tpm-values correlations
message("--Loading methy-tpm correlations...\n")
DBI::dbWriteTable(db_connect, "methy_tpm_corr_tb",
                  data.table::fread(methyl_tpm_corr, showProgress = FALSE))

# load gencode  methyl probe annotations
message("--Loading genecode array prob annotations...\n")
DBI::dbWriteTable(db_connect, "methyl_probe_annot_tb",
                  data.table::fread(methyl_probe_annot, showProgress = FALSE))

# load OpenPedCan EFO and MONDO annotations
message("--Loading OpenPedCan EFO and MONDO annotations...\n")
DBI::dbWriteTable(db_connect, "efo_mondo_annot_tb",
                  data.table::fread(efo_mondo_annot, showProgress = FALSE))

# merge array probe quantiles, correlations and gencode annotations
message("--merging quantiles, correlations, and probe annotations...\n")
if (exp_values == "gene") {
  methy_summary_table <- 
    dplyr::left_join(dplyr::tbl(db_connect, "methyl_probe_qtiles_tb"),
                     dplyr::tbl(db_connect, "methy_tpm_corr_tb"),
                     by = c("Probe_ID", "Dataset", "Disease")) %>% 
    dplyr::left_join(dplyr::tbl(db_connect, "methyl_probe_annot_tb") %>% 
                       dplyr::select(-transcript_id) %>% 
                       dplyr::distinct(), 
                     by = c("Probe_ID", "targetFromSourceId"))
} else {
  # load rna-seq expression tpm transcript representations
  message("--Loading rna-seq tpm transcript representation...\n")
  DBI::dbWriteTable(db_connect, "tpm_transcript_rep_tb",
                    data.table::fread(tpm_transcript_rep, showProgress = FALSE))

  methy_summary_table <- 
    dplyr::left_join(dplyr::tbl(db_connect, "methyl_probe_qtiles_tb"),
                     dplyr::tbl(db_connect, "methy_tpm_corr_tb"),
                     by = c("Probe_ID", "Dataset", "Disease")) %>% 
    dplyr::left_join(dplyr::tbl(db_connect, "methyl_probe_annot_tb") %>% 
                       dplyr::distinct(), 
                     by = c("Probe_ID", "transcript_id")) %>% 
    dplyr::left_join(dplyr::tbl(db_connect, "tpm_transcript_rep_tb") %>% 
                       dplyr::distinct(), 
                     by = c("transcript_id", "Dataset", "Disease"))
  
}

# Add EFO and MONDO codes associated with cancer type (Disease)
message("--adding EFO and MONDO codes associated with cancer types ...\n")
methy_summary_table <- dplyr::tbl(db_connect, "efo_mondo_annot_tb") %>%  
  dplyr::distinct() %>% 
  dplyr::rename(Disease = cancer_group, MONDO = mondo_code,
                diseaseFromSourceMappedId = efo_code) %>% 
  dplyr::right_join(methy_summary_table, by = "Disease")

# Add additional columns required for the OT portal
message("--inlcuding additional metadata required for the NCI MTP portal ...\n")
methy_summary_table <- methy_summary_table %>% 
  tidyr::as_tibble()
uuid_strings <- ids::uuid(nrow(methy_summary_table))
stopifnot(length(unique(uuid_strings)) == nrow(methy_summary_table))
methy_summary_table <- methy_summary_table %>% 
  dplyr::mutate(datatypeId = "Illumina_methylation_array",
                chop_uuid = uuid_strings, 
                datasourceId = "chop_gene_level_methylation")

# Write methylation summary table to RDS file - needed for API DB loading
message("--Writing methylation summary table to  file...\n")    
if (exp_values == "gene") {
  if (methyl_values == "beta") {
    methy_summary_table <-  methy_summary_table %>% 
      dplyr::select(Gene_symbol, targetFromSourceId, Dataset, Disease,
                    diseaseFromSourceMappedId, MONDO, RNA_Correlation, Probe_ID, 
                    Chromosome, Location, Beta_Q1, Beta_Q2, Beta_Median, Beta_Q4, 
                    Beta_Q5)
    methy_summary_table %>%
      readr::write_rds(file.path(results_dir, "gene-methyl-beta-values-summary.rds"))
    methy_summary_table %>% data.table::setDT() %>%
      data.table::fwrite(file.path(results_dir,
                                   "gene-methyl-beta-values-summary.tsv.gz"), 
                         sep="\t")
  } else {
    methy_summary_table <-  methy_summary_table %>% 
      dplyr::select(Gene_symbol, targetFromSourceId, Dataset, Disease,
                    diseaseFromSourceMappedId, MONDO, RNA_Correlation, Probe_ID, 
                    Chromosome, Location, M_Q1, M_Q2, M_Median, M_Q4, M_Q5) 
    methy_summary_table %>% 
      readr::write_rds(file.path(results_dir, "gene-methyl-m-values-summary.rds"))
    methy_summary_table %>% data.table::setDT() %>%
      data.table::fwrite(file.path(results_dir,
                                   "gene-methyl-m-values-summary.tsv.gz"), 
                         sep="\t")
  }
} else {
  if (methyl_values == "beta") {
    methy_summary_table <-  methy_summary_table %>%
      dplyr::select(Gene_symbol, targetFromSourceId, transcript_id, Dataset, 
                    Disease, diseaseFromSourceMappedId, MONDO, RNA_Correlation, 
                    Transcript_Representation, Probe_ID, Chromosome, Location, 
                    Beta_Q1, Beta_Q2, Beta_Median, Beta_Q4, Beta_Q5) 
    methy_summary_table %>%
      readr::write_rds(file.path(results_dir, "isoform-methyl-beta-values-summary.rds"))
    methy_summary_table %>% data.table::setDT() %>%
      data.table::fwrite(file.path(results_dir,
                                   "isoform-methyl-beta-values-summary.tsv.gz"), 
                         sep="\t")
  } else {
    methy_summary_table <-  methy_summary_table %>% 
      dplyr::select(Gene_symbol, targetFromSourceId, transcript_id, Dataset,
                    Disease,diseaseFromSourceMappedId, MONDO, RNA_Correlation, 
                    Transcript_Representation, Probe_ID, Chromosome, Location, 
                    M_Q1, M_Q2, M_Median, M_Q4, M_Q5) 
    methy_summary_table %>%
      readr::write_rds(file.path(results_dir, "isoform-methyl-m-values-summary.rds"))
    methy_summary_table %>% data.table::setDT() %>%
      data.table::fwrite(file.path(results_dir,
                                   "isoform-methyl-m-values-summary.tsv.gz"), 
                         sep="\t")
  }
} 
message("Analysis Done..\n")