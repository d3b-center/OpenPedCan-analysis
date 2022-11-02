# Author: Komal S. Rathi
# R version of 02_ependymoma_generate_all_data.py (Author: Teja Koganti)
# script to map DNA and RNA samples to a participant and assign disease group

# load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(dplyr)
  library(readr)
  library(optparse)
})

option_list <- list(
  make_option(c("--disease_group_file"), type = "character",
              help = "file with disease group info (tsv)"),
  make_option(c("--gistic"), 
              help = "gistic zip file"),
  make_option(c("--subfile_gistic_broad"), 
              help = "subfile of the zip folder that contains broad values by arm"),
  make_option(c("--subfile_gistic_focalbygene"), 
              help = "focal-cn-file-preparation based on gene"),
  make_option(c("--gsva"), 
              help = "gsva scores file"),
  make_option(c("--expr_dat"), 
              help = "expression subset file"),
  make_option(c("--fusion"), 
              help = "fusion results file"),
  make_option(c("--breakpoints_cnv"), 
              help = "breaks density  CNV summary file"),
  make_option(c("--breakpoints_sv"), 
              help = "breaks density  SV summary file"),
  make_option(c("--focal_gene_cn"), 
              help = "focal-cn-file-preparation based on gene"),
  make_option(c("--mutations"),
              help = 'consensus snv results file'),
  make_option(c("--outfile"), type = "character",
              help = "subfile of the GISTIC zip folder that contains focal data fro CDKN2A")
)

opt <- parse_args(OptionParser(option_list = option_list))
disease_group_file <- opt$disease_group_file
gistic <- opt$gistic
subfile_gistic_broad <- opt$subfile_gistic_broad
subfile_gistic_focalbygene <- opt$subfile_gistic_focalbygene
gsva <- opt$gsva
expr_dat <- opt$expr_dat
fusion <- opt$fusion
breakpoints_cnv <- opt$breakpoints_cnv
breakpoints_sv <- opt$breakpoints_sv
focal_gene_cn <- opt$focal_gene_cn
mutations <- opt$mutations
outfile <- opt$outfile

# Reading GISTIC broad_values and focal_by_genefile for CNA
broad_CNA <- read_tsv(unz(gistic, subfile_gistic_broad))
broad_CNA <- broad_CNA %>%
  column_to_rownames("Chromosome Arm")
gistic_focalCN <- read_tsv(unz(gistic, subfile_gistic_focalbygene))
gistic_focalCN_CDKN2A <- gistic_focalCN %>%
  filter(`Gene Symbol` == "CDKN2A") %>%
  column_to_rownames("Gene Symbol")
gistic_focalCN_CDKN2A <- t(gistic_focalCN_CDKN2A)
gistic_focalCN_MYCN <- gistic_focalCN %>%
  filter(`Gene Symbol` == "MYCN") %>%
  column_to_rownames("Gene Symbol")
gistic_focalCN_MYCN <- t(gistic_focalCN_MYCN)
gistic_focalCN_NF2 <- gistic_focalCN %>%
  filter(`Gene Symbol` == "NF2") %>%
  column_to_rownames("Gene Symbol")
gistic_focalCN_NF2 <- t(gistic_focalCN_NF2)

# Reading in gene set enrichment analyses file for GSEA scores for NFKB pathway
gsva <- read_tsv(gsva)
gsva_NFKB <- gsva %>% 
  filter(hallmark_name == "HALLMARK_TNFA_SIGNALING_VIA_NFKB") %>% 
  column_to_rownames('Kids_First_Biospecimen_ID')

# Reading subset gene expression file
expr_dat <- data.table::fread(expr_dat)
expr_dat <- expr_dat %>%
  column_to_rownames('GENE')

# Reading fusion summary file
fusion_df <- read_tsv(fusion)
fusion_df <- fusion_df %>%
  column_to_rownames("Kids_First_Biospecimen_ID")

# Reading chromosomal instability file for breakpoint density for CNV
breakpoint_density_cnv <- read_tsv(breakpoints_cnv)
breakpoint_density_cnv <- breakpoint_density_cnv %>%
  column_to_rownames("samples")

# Reading chromosomal instability  file for breakpoint for SV
breakpoint_density_sv <- read_tsv(breakpoints_sv)
breakpoint_density_sv <- breakpoint_density_sv %>%
  column_to_rownames("samples")

# Reading consensus focal CN results from analyses
focal_cn_gene <- read_tsv(focal_gene_cn)
focal_cn_gene_CDKN2A <- focal_cn_gene %>%
  filter(gene_symbol == "CDKN2A" & status %in% c("amplification", "gain", "loss")) %>%
  distinct(biospecimen_id, .keep_all = TRUE) %>%
  column_to_rownames('biospecimen_id')
focal_cn_gene_MYCN <- focal_cn_gene %>%
  filter(gene_symbol == "MYCN" & status %in% c("amplification", "gain", "loss")) %>%
  distinct(biospecimen_id, .keep_all = TRUE) %>%
  column_to_rownames('biospecimen_id')
focal_cn_gene_NF2 <- focal_cn_gene %>%
  filter(gene_symbol == "NF2" & status %in% c("amplification", "gain", "loss")) %>%
  distinct(biospecimen_id, .keep_all = TRUE) %>%
  column_to_rownames('biospecimen_id')

# Reading consensus snv results and filtering for EPN samples and NF2 mutations
mutations <- data.table::fread(mutations) %>%
  filter(Hugo_Symbol == "NF2")

# Reading the input in a  dataframe
EPN_notebook = read_tsv(disease_group_file)

# Get the list of DNA samples that made it through the pipeline
# All that are present in the GISTIC data passed consensus filtering.
# Others may be included or excluded in other CN data sets, but should be set to NA
cn_called_samples = colnames(broad_CNA)

# This function takes in broad CNA values from GISTIC along with chromosomal arm and gain/loss info
broad_CNA_fill_df <- function(x, broad_CNA_data, arm, loss_gain = c("loss", "gain")){
  biospecimen_DNA <- x[['Kids_First_Biospecimen_ID_DNA']]
  # no DNA results for this sample
  if(is.na(biospecimen_DNA)){
    return("NA")
  }
  CNA_value <- broad_CNA_data[arm, biospecimen_DNA]
  if(is.na(CNA_value) || is.null(CNA_value)){
    return("NA")
  } else if(CNA_value < 0 && loss_gain == "loss") {
    return("1")
  } else if(CNA_value > 0 && loss_gain == "gain"){
    return(1)
  } else {
    return(0)
  }
}

EPN_notebook["1q_loss"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "1q", loss_gain = "loss"))
EPN_notebook["1q_gain"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "1q", loss_gain = "gain"))
EPN_notebook["9p_loss"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "9p", loss_gain = "loss"))
EPN_notebook["9q_loss"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "9q", loss_gain = "loss"))
EPN_notebook["6p_loss"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "6p", loss_gain = "loss"))
EPN_notebook["6q_loss"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "6q", loss_gain = "loss"))
EPN_notebook["11q_loss"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "11q", loss_gain = "loss"))
EPN_notebook["11q_gain"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "11q", loss_gain = "gain"))
EPN_notebook["22p_loss"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "22p", loss_gain = "loss"))
EPN_notebook["22q_loss"] <- apply(EPN_notebook, MARGIN = 1, FUN = function(x) 
  broad_CNA_fill_df(x = x, broad_CNA_data = broad_CNA, arm = "22q", loss_gain = "loss"))

# This  function takes a dataframe whose values need to be used for final EPN_notebook  
# based on row_name, the corresponding value is returned
# If a sample is not in included_samples, it's values are set to NA
# (If included samples is blank, this is ignored)
fill_df <- function(sample, ref_df, col_name, included_samples = NULL, default = 0){
  if(is.na(sample)) { # no results for this sample
    return("NA")
  } else if(!is.null(included_samples) && !sample %in% included_samples) { # sample is not present in included samples, return NA
    return("NA")
  } else if(!sample %in% rownames(ref_df)){ # sample is not present in the reference data set, return default
    return(default)
  } else {
    value <- ref_df[sample, col_name]
    return(value)
  }
}

# Adding NKKB pathway GSEA score to the dataframe
EPN_notebook$NFKB_pathway_GSEAscore <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_RNA, function(x) fill_df(sample = x, ref_df = gsva_NFKB, col_name = "gsea_score"))

# Fill appropriate fusion summary information under each fusion
fusions_list = c("C11orf95--RELA", "LTBP3--RELA", "PTEN--TAS2R1",  "C11orf95--YAP1", "YAP1--MAMLD1", "YAP1--FAM118B", "C11orf95--MAML2")
fusion_df <- fusion_df[,fusions_list]
for(i in 1:length(fusions_list)){
  fusion <- fusions_list[i]
  EPN_notebook[,fusion] <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_RNA, function(x) fill_df(sample = x, ref_df = fusion_df, col_name = fusion))
}

# Adding breakpoints density for chromosomal instability to the dataframe
EPN_notebook[,"breaks_density-chromosomal_instability_CNV"] <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA, 
                                                                      function(x) fill_df(sample = x, ref_df = breakpoint_density_cnv, col_name = "breaks_density", included_samples = cn_called_samples))
EPN_notebook[,"breaks_density-chromosomal_instability_SV"] <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA, 
                                                                     function(x) fill_df(sample = x, ref_df = breakpoint_density_sv, col_name = "breaks_density", included_samples = cn_called_samples))

# Adding focal CN from GISTIC files for CDKN2A
EPN_notebook[,"GISTIC_focal_CN_CDKN2A"] <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA, 
                                                  function(x) fill_df(sample = x, ref_df = gistic_focalCN_CDKN2A, col_name = "CDKN2A", included_samples = cn_called_samples))
EPN_notebook[,"GISTIC_focal_CN_MYCN"] <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA, 
                                                  function(x) fill_df(sample = x, ref_df = gistic_focalCN_MYCN, col_name = "MYCN", included_samples = cn_called_samples))
EPN_notebook[,"GISTIC_focal_CN_NF2"] <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA, 
                                                function(x) fill_df(sample = x, ref_df = gistic_focalCN_NF2, col_name = "NF2", included_samples = cn_called_samples))

# Adding focal CN from CDKN2A from CNV consensus files in analyses
# Using status column from consensus_seg_annotated_cn_autosomes.tsv.gz file
EPN_notebook[,"consensus_focal_CN_CDKN2A"] <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA, 
                                                    function(x) fill_df(sample = x, ref_df = focal_cn_gene_CDKN2A, col_name = "status", included_samples = cn_called_samples))
EPN_notebook[,"consensus_focal_CN_MYCN"] <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA, 
                                                    function(x) fill_df(sample = x, ref_df = focal_cn_gene_MYCN, col_name = "status", included_samples = cn_called_samples))
EPN_notebook[,"consensus_focal_CN_NF2"] <- sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA, 
                                                   function(x) fill_df(sample = x, ref_df = focal_cn_gene_NF2, col_name = "status", included_samples = cn_called_samples))

mutation_fill_df <- function(sample, ref_df, col_name, default = 0){
  if(is.na(sample)) { # no results for this sample
    return("NA")
  } else if(!sample %in% ref_df$Tumor_Sample_Barcode){ # sample is not present in the reference data set, return default
    return(default)
  } else {
    value <- ref_df[ref_df$Tumor_Sample_Barcode == sample, col_name]
    return(value)
  }
}


EPN_notebook[,"NF2_variant_HGVSc"] <- unlist(sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA,
                                          function(x) mutation_fill_df(sample = x, ref_df = mutations, col_name = 'HGVSc')))
EPN_notebook[,"NF2_variant_consequence"] <- unlist(sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA,
                                          function(x) mutation_fill_df(sample = x, ref_df = mutations, col_name = 'Consequence')))
EPN_notebook[,"NF2_variant_classification"] <- unlist(sapply(EPN_notebook$Kids_First_Biospecimen_ID_DNA,
                                                   function(x) mutation_fill_df(sample = x, ref_df = mutations, col_name = 'Variant_Classification')))

# Adding expression z-scores to dataframe
genes_of_interest = c("RELA", "L1CAM", "ARL4D", "CLDN1", "CXorf67", "TKTL1", "GPBP1", "IFT46", "MYCN", "NF2")
subset_df <- expr_dat[genes_of_interest, intersect(EPN_notebook$Kids_First_Biospecimen_ID_RNA, colnames(expr_dat))]
# log2(x + 1) transform the expression matrix
log_expression <- log2(subset_df + 1)
# Scale the gene values -- scale() works on the columns, hence the transpose
z_scored_expression <- scale(t(log_expression),
                             center = TRUE,
                             scale = TRUE)
z_scored_expression <- as.data.frame(z_scored_expression)
colnames(z_scored_expression) <-  paste0(colnames(z_scored_expression), "_expr_zscore")
EPN_notebook <- EPN_notebook %>%
  left_join(z_scored_expression %>%
              rownames_to_column("Kids_First_Biospecimen_ID_RNA"))

# sort
EPN_notebook <- EPN_notebook %>%
  arrange(Kids_First_Participant_ID, sample_id)

# write to output file
readr::write_tsv(EPN_notebook, outfile)
