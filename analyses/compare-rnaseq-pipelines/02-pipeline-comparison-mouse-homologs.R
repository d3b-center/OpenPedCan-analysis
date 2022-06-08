# Read RNA-Seq counts from varying workflows to compare 
# This script runs analysis to compare only genes that are homologous between humans and mouse
# Expected output: Correlation coefficient at the gene level, standard error, and probable error of the correlation coefficient


suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(tidyr)
  library(dplyr)
  library(corrplot)
})

option_list <- list(
  make_option(c("-j", "--wf1_name"), type = "character",
              help = "first workflow source name [PPTC/KF/JAX]"),
  make_option(c("-x", "--wf1_file"), type = "character",
              help = "Input RNA-Seq file from first workflow (.tsv)"),
  make_option(c("-k", "--wf2_name"), type = "character",
              help = "second workflow source name [PPTC/KF/JAX]"),
  make_option(c("-y", "--wf2_file"), type = "character",
              help = "Input RNA-Seq file from second workflow (.tsv)"),
  make_option(c("-c", "--input_homologs"), type  = "character",
              help = "Input homologs to filter genes (.tsv)"),
  make_option(c("-o", "--output_filename"), type = "character", 
              default = "comparison-results",
              help = "Output filename suffix ")
)

# parse the parameters
opt <- parse_args(OptionParser(option_list = option_list))
wf1_name <- opt$wf1_name
#wf1_name <- 'KF'
wf2_name <- opt$wf2_name
#wf2_name <- 'JAX'
df_wf1 <- opt$wf1_file
#df_wf1 <- 'input/PPTC-KF-gene-expression-rsem-tpm-collapsed-matrix.tsv'
df_wf2 <- opt$wf2_file
#df_wf2 <- 'input/PPTC-JAX-gene-expression-rsem-tpm-collapsed-matrix.tsv'
input_homologs <- opt$input_homologs
#input_homologs <- 'input/Gene_ID_Matches.tsv'
output_filename <- opt$output_filename


# Create output dir ------------------------------------------------------------

# Set path to results, plots, and subset files directories
#module_dir <- file.path("analyses", "pipeline-comparison")
out_dir <- file.path("results")

# Source function to gather counts and frequency calculation per cohort and cancer_group
#source(file.path(module_dir,"utils","compare_RNASeq_pipelines.R"))
source(file.path("utils","compare_RNASeq_pipelines.R"))

# Create results folder if it doesn't exist
if (!dir.exists(out_dir)) {
  dir.create(out_dir)
}

# Read data
message('Read data...')


# Read data for homologs between mouse and humans
df_homologs <- read.table(file = input_homologs,header = TRUE,sep = "\t")


df1 <- paste(wf1_name,"data",sep="")
df1 <- read_tsv(df_wf1) %>%
  as.data.frame() %>%
  filter(gene_id %in% df_homologs$Gene.name)
rownames(df1) <- df1$gene_id
df1$gene_id <- NULL
df1 <- as.matrix(df1)

df2 <- paste(wf2_name,"data",sep="")
df2 <- read_tsv(df_wf2) %>%
  as.data.frame() %>%
  filter(gene_id %in% df_homologs$Gene.name)
rownames(df2) <- df2$gene_id
df2$gene_id <- NULL
df2 <- as.matrix(df2)



# Run QC on input files
message('Perform data QC...')
qc_matrices <- qc_matrix_input(df1, df2)
wf1_mat <- qc_matrices[[1]]
wf2_mat <- qc_matrices[[2]]


# Run workflow comparison
message('Perform workflow comparison...')
result_mat <- calculate_matrix_cor(wf1_mat,wf2_mat,wf1_name,wf2_name,out_dir,output_filename)

#output_filename <- paste("results",wf1_name,wf2_name,"comparison",sep = "_")
write.table(result_mat, file=paste(out_dir,"//",output_filename,".tsv",sep=""), sep="\t", col.names = T, row.names = F,quote = F)




