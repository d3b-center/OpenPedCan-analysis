# Authors: Komal S. Rathi, Jo Lynne Rokita
# Script to gather relevant data for EPN subtyping

# Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(data.table)
  library(optparse)
})

# Define options
option_list <- list(
  make_option(c("--disease_group_file"), type = "character", help = "file with disease group info (tsv)"),
  make_option(c("--gistic"), help = "gistic zip file"),
  make_option(c("--subfile_gistic_broad"), help = "subfile of the zip folder that contains broad values by arm"),
  make_option(c("--subfile_gistic_focalbygene"), help = "focal-cn-file-preparation based on gene"),
  make_option(c("--gsva"), help = "gsva scores file"),
  make_option(c("--expr_dat"), help = "expression subset file"),
  make_option(c("--fusion"), help = "fusion results file"),
  make_option(c("--breakpoints_cnv"), help = "breaks density CNV summary file"),
  make_option(c("--breakpoints_sv"), help = "breaks density SV summary file"),
  make_option(c("--focal_gene_cn"), help = "focal-cn-file-preparation based on gene"),
  make_option(c("--mutations"), help = 'consensus snv results file'),
  make_option(c("--TumorOnlySNV"), help = 'tumor only snv results file'),
  make_option(c("--outfile"), type = "character", help = "Output file path")
)

# Parse arguments
opt <- parse_args(OptionParser(option_list = option_list))

# Load data
## samples of interest
epn_notebook <- read_tsv(opt$disease_group_file)

## GSVA/Expression/Fusions
gsva <- read_tsv(opt$gsva) %>%
  filter(hallmark_name == "HALLMARK_TNFA_SIGNALING_VIA_NFKB",
         Kids_First_Biospecimen_ID %in% epn_notebook$Kids_First_Biospecimen_ID) %>%
  column_to_rownames("Kids_First_Biospecimen_ID")
expr_dat <- fread(opt$expr_dat) %>%
  column_to_rownames("GENE") # already subsetted
fusion_df <- read_tsv(opt$fusion) %>%
  filter(Kids_First_Biospecimen_ID %in% epn_notebook$Kids_First_Biospecimen_ID) %>%
  column_to_rownames("Kids_First_Biospecimen_ID")

## CNV/SV
opt$subfile_gistic_broad <- "cnv-consensus-gistic/broad_values_by_arm.txt"
opt$subfile_gistic_focalbygene <- "cnv-consensus-gistic/focal_data_by_genes.txt"

# Define a temporary directory to extract the gistic files
temp_dir <- tempdir()
# Construct the path to the extracted file
extracted_file_path_broad <- file.path(temp_dir, opt$subfile_gistic_broad)
extracted_file_path_focal <- file.path(temp_dir, opt$subfile_gistic_focalbygene)
# Extract the specific file from the zip archive
unzip(zipfile = opt$gistic, files = c(opt$subfile_gistic_broad, 
                                      opt$subfile_gistic_focalbygene),
                                      exdir = temp_dir, overwrite = TRUE)

# Read in the extracted files
broad_CNA <- read_tsv(extracted_file_path_broad) %>%
    column_to_rownames("Chromosome Arm")
gistic_focalCN <- read_tsv(extracted_file_path_focal) %>%
  filter(`Gene Symbol` %in% c("CDKN2A", "MYCN", "NF2")) %>%
  column_to_rownames("Gene Symbol") %>%
  select(-c(`Gene ID`, Cytoband)) %>%
  t()

# Delete the extracted files after processing
unlink(c(extracted_file_path_broad, extracted_file_path_focal))

# focal consensus calls
focal_cn_gene <- data.table::fread(opt$focal_gene_cn) %>%
  filter(biospecimen_id %in% epn_notebook$Kids_First_Biospecimen_ID) %>%
  filter(gene_symbol %in% c("CDKN2A", "MYCN", "NF2"),
         status %in% c("amplification", "gain", "loss"))

# breakpoint density
breakpoint_density_cnv <- read_tsv(opt$breakpoints_cnv) %>%
  filter(samples %in% epn_notebook$Kids_First_Biospecimen_ID) %>%
  column_to_rownames("samples")
breakpoint_density_sv <- read_tsv(opt$breakpoints_sv) %>%
  filter(samples %in% epn_notebook$Kids_First_Biospecimen_ID) %>%
  column_to_rownames("samples")

## Mutations  
TumorOnly_SNV <- data.table::fread(opt$TumorOnlySNV) %>%
  select(!grepl("gnomad")) %>% 
  filter(Hugo_Symbol %in% c("NF2", "H3-3A", "H3-3B", "H3C2", "H3C3", "H3C14"))
mutations <- data.table::fread(opt$mutations) %>%
  filter(Hugo_Symbol %in% c("NF2", "H3-3A", "H3-3B", "H3C2", "H3C3", "H3C14"),
         Tumor_Sample_Barcode %in% epn_notebook$Kids_First_Biospecimen_ID)
mutations <- mutations %>% 
  bind_rows(TumorOnly_SNV) %>%
  filter(Tumor_Sample_Barcode %in% epn_notebook$Kids_First_Biospecimen_ID)

# Get the list of DNA samples that made it through the pipeline
# All that are present in the GISTIC data passed consensus filtering.
# Others may be included or excluded in other CN data sets, but should be set to NA
cn_called_samples <- colnames(broad_CNA)
rna_samples <- rownames(fusion_df)

# Function to fill data
fill_df <- function(sample, ref_df, col_name, default = 0){
  if(is.na(sample)) return(NA)
  if(!sample %in% ref_df$Kids_First_Biospecimen_ID) return(default)
  ref_df %>% filter(Kids_First_Biospecimen_ID == sample) %>% pull({{col_name}})
}

# This function takes in broad CNA values from GISTIC along with chromosomal arm and gain/loss info
broad_CNA_fill_df <- function(x, broad_CNA_data, arm, loss_gain = c("loss", "gain")){
  biospecimen_DNA <- x[['Kids_First_Biospecimen_ID']]
  # no DNA results for this sample
  if(is.na(biospecimen_DNA)){
    return(NA)
  }
  CNA_value <- broad_CNA_data[arm, biospecimen_DNA]
  if(is.na(CNA_value) || is.null(CNA_value)){
    return(NA)
  } else if(CNA_value < 0 && loss_gain == "loss") {
    return("1")
  } else if(CNA_value > 0 && loss_gain == "gain"){
    return(1)
  } else {
    return(0)
  }
}


# Process and fill data in epn_notebook
# loop through regions of interest
for(arm_of_interest in c("1q", "6p", "6q", "9p", "9q", "11q", "22p")) {
  epn_notebook[paste0(arm_of_interest, "_loss")] <- apply(epn_notebook, MARGIN = 1, FUN = function(x) 
    broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = arm_of_interest, loss_gain = "loss"))
  epn_notebook[paste0(arm_of_interest, "_gain")] <- apply(epn_notebook, MARGIN = 1, FUN = function(x) 
    broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = arm_of_interest, loss_gain = "gain"))
}
 
# This  function takes a dataframe whose values need to be used for final epn_notebook  
# based on row_name, the corresponding value is returned
# If a sample is not in included_samples, it's values are set to NA
# (If included samples is blank, this is ignored)
fill_df <- function(sample, ref_df, col_name, included_samples = NULL, default = 0){
  if(is.na(sample)) { # no results for this sample
    return(NA)
  } else if(!is.null(included_samples) && !sample %in% included_samples) { # sample is not present in included samples, return NA
    return(NA)
  } else if(!sample %in% rownames(ref_df)){ # sample is not present in the reference data set, return default
    return(default)
  } else {
    value <- ref_df[sample, col_name]
    return(value)
  }
}

# Adding NKKB pathway GSEA score to the dataframe
epn_notebook$NFKB_GSEAscore <- sapply(epn_notebook$Kids_First_Biospecimen_ID, 
                                              function(x) fill_df(sample = x, ref_df = gsva, col_name = "gsea_score", 
                                                                  included_samples = rna_samples))

# Fill appropriate fusion summary information under each fusion
fusions_list = c("ZFTA--RELA", "ZFTA--MAML2", "YAP1--MAMLD1", "YAP1--FAM118B", "YAP1--MAML2", "PTEN--TAS2R1")
fusion_df <- fusion_df[,fusions_list]
for(i in 1:length(fusions_list)){
  fusion <- fusions_list[i]
  epn_notebook[,fusion] <- sapply(epn_notebook$Kids_First_Biospecimen_ID, function(x) fill_df(sample = x, ref_df = fusion_df, col_name = fusion, 
                                                                                              included_samples = rna_samples))
}

# Adding breakpoints density for chromosomal instability to the dataframe
epn_notebook[,"breakpoint_density_CNV"] <- sapply(epn_notebook$Kids_First_Biospecimen_ID, 
                                                                      function(x) fill_df(sample = x, ref_df = breakpoint_density_cnv, col_name = "breaks_density", included_samples = cn_called_samples))
epn_notebook[,"breakpoint_density_SV"] <- sapply(epn_notebook$Kids_First_Biospecimen_ID, 
                                                                     function(x) fill_df(sample = x, ref_df = breakpoint_density_sv, col_name = "breaks_density", included_samples = cn_called_samples))

# Adding focal CN from GISTIC files for CDKN2A
for (gene in c("CDKN2A", "MYCN", "NF2")) {
  epn_notebook[,paste0("GISTIC_focal_CN_", gene)] <- sapply(epn_notebook$Kids_First_Biospecimen_ID, 
                                                 function(x) fill_df(sample = x, ref_df = gistic_focalCN, col_name = gene, 
                                                                     included_samples = cn_called_samples))
}

# Adding focal CN from CNV consensus files in analyses
# Using status column from consensus_seg_annotated_cn_autosomes.tsv.gz file
for (goi in c("CDKN2A", "MYCN", "NF2")) {
  focal_cn_gene_filtered <- focal_cn_gene %>%
    filter(gene_symbol == goi) %>%
    column_to_rownames("biospecimen_id")
  epn_notebook[,paste0("consensus_focal_CN_", goi)] <- sapply(epn_notebook$Kids_First_Biospecimen_ID, 
                                                    function(x) fill_df(sample = x, ref_df = focal_cn_gene_filtered, 
                                                                        col_name = "status", included_samples = cn_called_samples))
}


# Function for filling mutations
mutation_fill_df <- function(sample, ref_df, col_name, default = 0){
  ref_df <-  ref_df %>% as_tibble()
  if(is.na(sample)) { # no results for this sample
    return(NA)
  } else if(!sample %in% ref_df$Tumor_Sample_Barcode){ # sample is not present in the reference data set, return default
    return(default)
  } else {
    value <- ref_df[ref_df$Tumor_Sample_Barcode == sample, col_name]
    return(value)
  }
}

nf2_df <- mutations %>% filter(Hugo_Symbol == "NF2")
epn_notebook[,"NF2_variant_HGVSc"] <- unlist(sapply(epn_notebook$Kids_First_Biospecimen_ID,
                                                    function(x) mutation_fill_df(sample = x, ref_df = nf2_df, col_name = 'HGVSc')))
epn_notebook[,"NF2_variant_consequence"] <- unlist(sapply(epn_notebook$Kids_First_Biospecimen_ID,
                                                          function(x) mutation_fill_df(sample = x, ref_df = nf2_df, col_name = 'Consequence')))
epn_notebook[,"NF2_variant_classification"] <- unlist(sapply(epn_notebook$Kids_First_Biospecimen_ID,
                                                             function(x) mutation_fill_df(sample = x, ref_df = nf2_df, col_name = 'Variant_Classification')))

mutation_gene <- mutations %>% filter(Hugo_Symbol == "H3-3A" & HGVSp_Short == 'p.K28M')
epn_notebook[,"H3-3A_HGVSp_Short"] <- unlist(sapply(epn_notebook$Kids_First_Biospecimen_ID,
                                                    function(x) mutation_fill_df(sample = x, ref_df = mutation_gene, col_name = 'HGVSp_Short')))

mutation_gene <- mutations %>% filter(Hugo_Symbol == "H3-3B" & HGVSp_Short == 'p.K28M')
epn_notebook[,"H3-3B_HGVSp_Short"] <- unlist(sapply(epn_notebook$Kids_First_Biospecimen_ID,
                                                    function(x) mutation_fill_df(sample = x, ref_df = mutation_gene, col_name = 'HGVSp_Short')))
mutation_gene <- mutations %>% filter(Hugo_Symbol == "H3C2" & HGVSp_Short == 'p.K28M')
epn_notebook[,"H3C2_HGVSp_Short"] <- unlist(sapply(epn_notebook$Kids_First_Biospecimen_ID,
                                                   function(x) mutation_fill_df(sample = x, ref_df = mutation_gene, col_name = 'HGVSp_Short')))
mutation_gene <- mutations %>% filter(Hugo_Symbol == "H3C3" & HGVSp_Short == 'p.K28M')
epn_notebook[,"H3C3_HGVSp_Short"] <- unlist(sapply(epn_notebook$Kids_First_Biospecimen_ID,
                                                   function(x) mutation_fill_df(sample = x, ref_df = mutation_gene, col_name = 'HGVSp_Short')))
mutation_gene <- mutations %>% filter(Hugo_Symbol == "H3C14" & HGVSp_Short == 'p.K28M')
epn_notebook[,"H3C14_HGVSp_Short"] <- unlist(sapply(epn_notebook$Kids_First_Biospecimen_ID,
                                                    function(x) mutation_fill_df(sample = x, ref_df = mutation_gene, col_name = 'HGVSp_Short')))


# Adding expression z-scores to dataframe
genes_of_interest = c("RELA", "L1CAM", "ARL4D", "CLDN1", "EZHIP", "TKTL1", "GPBP1", "IFT46", "MYCN", "NF2")
subset_df <- expr_dat[genes_of_interest, colnames(expr_dat)]
# log2(x + 1) transform the expression matrix
log_expression <- log2(subset_df + 1)
# Scale the gene values -- scale() works on the columns, hence the transpose
z_scored_expression <- scale(t(log_expression),
                             center = TRUE,
                             scale = TRUE)
z_scored_expression <- as.data.frame(z_scored_expression)
colnames(z_scored_expression) <-  paste0(colnames(z_scored_expression), "_expr_zscore")

epn_notebook <- epn_notebook %>%
  left_join(z_scored_expression %>%
              rownames_to_column("Kids_First_Biospecimen_ID"))

# pull all data together by match_id
epn_meta <- epn_notebook %>%
  select(1:disease_group)

epn_data <- epn_notebook %>%
  select(c(match_id, `1q_loss`:ncol(epn_notebook))) %>%
  group_by(match_id) %>%
  summarize(across(everything(), ~paste(unique(na.omit(.x)), collapse = ", ")), .groups = 'drop')

epn_meta_data_join <- epn_meta %>%
  left_join(epn_data) %>%
  arrange(Kids_First_Participant_ID, match_id)


# Writing output
readr::write_tsv(epn_meta_data_join, opt$outfile)
