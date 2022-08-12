# Prepocess raw Illumina Infinium HumanMethylation BeadArrays (27K, 450K, and 850k) 
# intensities using minfi into usable methylation measurements (Beta and M values) 
# for TARGET normal and tumor samples.

# Eric Wafula for Pediatric OpenTargets
# 12/27/2021

# Load libraries:
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
suppressWarnings(
  suppressPackageStartupMessages(library(minfi))
)

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# set up optparse options
option_list <- list(
  make_option(opt_str = "--base_dir", type = "character", default = NULL,
              help = "The absolute path of the base directory containing sample 
              array IDAT files.",
              metavar = "character"),
  
  make_option(opt_str = "--metadata_file", type = "character", default = NULL,
              help = "The metedata file associated with the sample array data
              files.",
              metavar = "character"),
  
  make_option(opt_str = "--preprocess_method", type = "character", 
              default = "preprocessQuantile",
              help = "preprocesses the Illumina methylation array using the of
              the following minfi methods: preprocessQuantile, preprocessFunnorm, 
              or preprocessIllumina.
              Default is preprocessQuantile",
              metavar = "character"),
  
  make_option(opt_str = "--snp_filter", action = "store_true", default = TRUE, 
              help = "If TRUE, drops the probes that contain either a SNP at
              the CpG interrogation or at the single nucleotide extension.
              Default is TRUE",
              metavar = "character")
)


# parse parameter options
opt <- parse_args(OptionParser(option_list = option_list))
base_dir <- opt$base_dir
metadata_file <- opt$metadata_file
preprocess_method <- opt$preprocess_method
snp_filter <- opt$snp_filter

# get analysis dataset from arrays base_dir
dataset <- basename(base_dir)
message("===============================================")
message(c("Preprocessing ", dataset, " sample array data files..."))
message("===============================================\n")

######################### Create metadata sample sheet #########################
message("Creating metadata sample sheet...\n")

if (grepl("TARGET", metadata_file, fixed = TRUE)) {
  # read metadata file
  metadata <- readr::read_tsv(metadata_file, guess_max = 10000,
                              show_col_types = FALSE)
  # Select the required columns and rename appropriately
  metadata %>% dplyr::select(as.name("Characteristics[DiseaseState]"), 
                             as.name("Characteristics[OrganismPart]"), 
                             as.name("Extract Name")) %>% 
    dplyr::rename(Sample_Type = as.name("Characteristics[DiseaseState]"), 
                  Primary_Site = as.name("Characteristics[OrganismPart]"), 
                  Sample_Name = as.name("Extract Name")) %>% 
    dplyr::mutate(Sample_Group = 
                    dplyr::case_when(
                      Sample_Type == "Normal" ~ "Normal",
                      Sample_Type != "Normal" ~ "Tumor")) %>%
    dplyr::distinct() %>% 
    dplyr::mutate(Basename = file.path(base_dir, Sample_Name)) %>% 
    readr::write_csv(file.path(base_dir, "SampleSheet.csv"))
  rm(metadata) 
}
if (grepl("CBTN", metadata_file, fixed = TRUE)) {
  # read metadata file
  metadata <- readr::read_csv(metadata_file, guess_max = 10000,
                              show_col_types = FALSE)
  # Select the required columns and rename appropriately
  metadata %>% dplyr::select(disease_type, sample_type, primary_site,
                             as.name("Kids First Biospecimen ID")) %>% 
    dplyr::rename(Sample_Type = disease_type,
                  Primary_Site = primary_site,
                  Sample_Group = sample_type, 
                  Sample_Name = as.name("Kids First Biospecimen ID")) %>% 
    dplyr::mutate(Sample_Group = 
                    replace(Sample_Group, 
                            Sample_Group == "Non-Tumor", "Normal")) %>% 
    dplyr::distinct() %>%
    dplyr::mutate(Basename = file.path(base_dir, Sample_Name)) %>%
    readr::write_csv(file.path(base_dir, "SampleSheet.csv"))
  rm(metadata)
}

########################### Read sample array data  ############################
message("Reading sample array data files...\n")

# load sample sheet 
sample_sheet <- suppressWarnings(
  minfi::read.metharray.sheet(base_dir, pattern = "csv$")
)

# load array data into a RGChannelSet object
RGSet <- suppressWarnings(
  minfi::read.metharray.exp(targets = sample_sheet, 
                            verbose = TRUE, force = TRUE)
)
rm(sample_sheet)

####################### Preprocessing and normalization ########################
message("\nPreprocessing and normalizing...\n")

# check if preprocessing and normalization valid
norm_methods <-  c("preprocessIllumina", "preprocessQuantile",
                          "preprocessFunnorm")
stopifnot(preprocess_method %in% norm_methods)

# process data into a GenomicRatioSet object
if (preprocess_method == "preprocessIllumina") {  # preprocessIllumina
  MSet <- RGSet %>% 
    minfi::preprocessIllumina(bg.correct = TRUE, normalize = "controls")
  GRset <- MSet %>% 
    minfi::mapToGenome() %>% 
    minfi::ratioConvert(what = "both", keepCN = TRUE)
} else if (preprocess_method == "preprocessFunnorm") { 
  GRset <- RGSet %>% 
    minfi::preprocessFunnorm(RGSet)
} else { 
  # processQuantile
  GRset <- RGSet %>%  
    minfi::preprocessQuantile(fixOutliers = TRUE, removeBadSamples = TRUE, 
                       quantileNormalize = TRUE, stratified = TRUE, 
                       mergeManifest = FALSE)
}
rm(RGSet)

if (snp_filter) {
  ########################## Remove probes with SNPs ############################
  message("\nRemoving probes with SNPs...\n")
  
  # removing probes with SNPs inside the probe body 
  # or at the nucleotide extension
  GRset <- GRset %>% 
    minfi::addSnpInfo() %>% 
    minfi::dropLociWithSnps(snps=c("SBE","CpG"), maf=0)
}

############################## Summarize results ###############################
message("Summarizing results...\n")

# data summary functions
summarize_results <- function(meth_values, col_data, annot_data) {
  # format methylation values
  meth_values <- meth_values %>% 
    as.data.frame()
  meth_values_df <- meth_values
  meth_values_df$Probe <- row.names(meth_values)
  rm(meth_values)
  meth_values_df <- meth_values_df %>% 
    tibble() %>% 
    dplyr::filter(Probe %in% annot_data$Probe) %>%
    tidyr::pivot_longer(!Probe, names_to = "Sample_Name", 
                        values_to = "Meth_Value")

  # merge sample metadata to the methylation values to create a summary table
  summary_table <- meth_values_df %>% 
    dplyr::inner_join(col_data, by = "Sample_Name")
  rm(meth_values_df)
  
  # merge probe annotations to summary table
  summary_table <- summary_table %>%
    dplyr::inner_join(annot_data, by = "Probe")
  
return(summary_table)  
}

# extract relevant methylation values, metadata and annotations from the 
# GenomicRatioSet object
# methylation values
m_values <- minfi::getM(GRset)
beta_values <- minfi::getBeta(GRset)
# sample metadata
col_data <- SummarizedExperiment::colData(GRset)
col_data <- col_data %>% 
  as.data.frame() %>% 
  tibble() %>% 
  dplyr::select(Sample_Name, Primary_Site, Sample_Type, predictedSex) %>% 
  dplyr::rename(Predicted_Sex = predictedSex)
# probe annotations 
annot_data <- minfi::getAnnotation(GRset)
if (dataset == "AML27k") {
  annot_data <- annot_data %>% 
    as.data.frame() %>% 
    tibble() %>%
    dplyr::select(chr, pos, Name, Symbol, Accession) %>% 
    dplyr::filter(Accession != "") %>%
    dplyr::rename(Chromosome = chr, Position = pos, Probe = Name)
  } else {
    annot_data <- annot_data %>% 
      as.data.frame() %>% 
      tibble() %>%
      dplyr::select(chr, pos, Name, UCSC_RefGene_Name, 
                    UCSC_RefGene_Accession, UCSC_RefGene_Group) %>% 
      dplyr::filter(UCSC_RefGene_Accession != "") %>%
      dplyr::rename(Chromosome = chr, Position = pos, Probe = Name)
}
rm(GRset)

# write M-values methylation summary table to TSV file
m_values_file <- file.path(paste0(dataset, "-m-values-methylation.tsv"))
summary_table <- summarize_results(m_values, col_data, annot_data)
summary_table %>%
 data.table::setDT() %>%
 data.table::fwrite(m_values_file, sep="\t")
rm(summary_table)
# print out completion message
message(paste(dataset,"samples methylation 'M-values'saved to:\n", 
              m_values_file, "\n"))

# write Beta-values methylation summary table to TSV file
beta_values_file <- file.path(paste0(dataset, "-beta-values-methylation.tsv"))
summary_table <- summarize_results(beta_values, col_data, annot_data)
rm(col_data, annot_data)
summary_table %>%
 data.table::setDT() %>%
 data.table::fwrite(beta_values_file, sep="\t")
rm(summary_table)
# print out completion message
message(paste(dataset, "samples methylation 'Beta-values'saved to:\n", 
              beta_values_file, "\n"))
