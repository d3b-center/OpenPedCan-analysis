# This script performs the following functions:
# 1. DESeq2 tumor-only analysis with RUVg by molecular subtype
# Authors: Komal Rathi, updated by Adam Kraya

suppressPackageStartupMessages({
  library(optparse)
  library(tidyverse)
  library(DESeq2)
  library(RUVSeq)
  library(EDASeq)
  library(edgeR)
  library(stringr)
  library(data.table)
})

# parse parameters
option_list <- list(
  make_option(
    opt_str = "--dataset",
    type = "character",
    help = "Give any name to the dataset to create output folder"
  ),
  make_option(
    opt_str = "--cancer_group_values",
    type = "character",
    help = "cancer group value"
  ),
  make_option(
    opt_str = "--cohort_values",
    type = "character",
    help = "cohort value"
  ),
  make_option(
    opt_str = "--k_value",
    type = "character",
    help = "number of K values to evaluate"
  ),
  make_option(
    opt_str = "--pos_c",
    type = "character",
    help = "path to file of positive control genes"
  ),
  make_option(
    opt_str = "--neg_c",
    type = "character",
    help = "path to file of negative control genes"
  )
)

# extract parameters
opt <- parse_args(OptionParser(option_list = option_list))
dataset <- opt$dataset
cancer_group_values <-
  unlist(stringr::str_split(opt$cancer_group_values, ','))
cohort_values <- unlist(stringr::str_split(opt$cohort_values, ','))
k_value <- as.numeric(opt$k_value)
neg_ctrl_genes.f <- opt$neg_c
pos_ctrl_genes.f <- opt$pos_c

# establish directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
scratch_dir <- file.path(root_dir, 'scratch')
analysis_dir <-
  file.path(root_dir, 'analyses', 'rnaseq-batch-correct')
input_dir <- file.path(analysis_dir, 'input')
plots_dir <- file.path(scratch_dir, 'plots', dataset)
if (!dir.exists(plots_dir)) {
  dir.create(plots_dir, recursive = TRUE)
}

output_dir <- file.path(scratch_dir, 'output', dataset)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

norm_count_dir <- file.path(scratch_dir, 'normalized_counts')
if (!dir.exists(norm_count_dir)) {
  dir.create(norm_count_dir, recursive = TRUE)
}

# source functions
source('util/deseq2_pvals_histogram.R') # DESeq2 pval histograms
source('util/edaseq_plot.R') # PCA and UMAP clustering
source('util/ruvg.R') # function to run RUVg

# read histology
message("Reading in histologies file")
htl_df <- data.table::fread('../../data/histologies.tsv')

# read expected counts
message("Reading RSEM expected counts file")
cnt_df <-
  readRDS('../../data/gene-counts-rsem-expected_count-collapsed.rds')

# Read in positive and negative control gene sets
pos_ctrl_genes <- readRDS(file.path(input_dir, pos_ctrl_genes.f))
neg_ctrl_genes <- readRDS(file.path(input_dir, neg_ctrl_genes.f))
pos_neg_ctrl_genes <- c(neg_ctrl_genes, pos_ctrl_genes)

# filter histology

selected_htl_df <- htl_df %>%
  .[experimental_strategy == "RNA-Seq"] %>%
  .[sample_type == "Tumor"] %>%
  .[cancer_group %in% cancer_group_values] %>%
  .[!is.na(molecular_subtype)]

# filter expression
cnt_df <- cnt_df %>%
  dplyr::select(intersect(selected_htl_df$Kids_First_Biospecimen_ID, colnames(cnt_df)))
cnt_df <- cnt_df[rowSums(cnt_df) > 0, ]

selected_htl_df <- selected_htl_df %>%
  dplyr::filter(Kids_First_Biospecimen_ID %in% colnames(cnt_df))

# filter by expression and convert to DGElist
bs_id <-
  gsub('TARGET-[0-9]{2}-',
       '',
       selected_htl_df$Kids_First_Biospecimen_ID) # shorten bs ids for TARGET samples
molecular_subtype <-
  factor(as.character(selected_htl_df$molecular_subtype))
RNA_library <- factor(as.character(selected_htl_df$RNA_library))
design <- model.matrix(~ molecular_subtype)
counts_object <-
  edgeR::DGEList(counts = cnt_df, group = molecular_subtype)
counts_object_filtered <-
  edgeR::filterByExpr(counts_object, group = molecular_subtype)
counts_object <-
  counts_object[counts_object_filtered, , keep.lib.sizes = FALSE]

# create new expression set
seq_expr_set <-
  EDASeq::newSeqExpressionSet(
    counts = round(counts_object$counts),
    phenoData = data.frame(bs_id, molecular_subtype, RNA_library, row.names = colnames(round(
      counts_object$counts
    )))
  )

########################################### DESeq2 analysis ##############################################################

# 1.1. RUVg using hk genes in normals only (full HRT atlas)

ruvg_out <-
  ruvg_test(
    seq_expr_set = seq_expr_set,
    k_val = 1:k_value,
    emp_neg_ctrl_genes = neg_ctrl_genes,
    prefix = "hk_genes_normals",
    diff_type = "deseq2",
    output_dir = output_dir,
    plot_dir = plots_dir,
    design_variable = "molecular_subtype",
    color_var = "RNA_library",
    shape_var = "RNA_library"
  )

message("Batch correction DGE complete")

# Non-batch corrected DESeq2::DESeq performs a default analysis through the steps:
# - estimation of size factors: estimateSizeFactors
# - estimation of dispersion: estimateDispersions
# - Negative Binomial GLM fitting and Wald statistics: nbinomWaldTest

########################################### DESeq2 analysis ##############################################################


message("Running non-batch corrected DESeq2 analysis")
dds_nobatch <-
  DESeq2::DESeqDataSetFromMatrix(
    countData = round(counts_object$counts),
    colData =  data.frame(bs_id, molecular_subtype),
    design = design
  )
dds_nobatch <- DESeq2::DESeq(dds_nobatch)
dge_output_nobatch <-
  DESeq2::results(dds_nobatch,
                  cooksCutoff = FALSE,
                  pAdjustMethod = 'BH')
dge_output_nobatch <- dge_output_nobatch %>%
  as.data.frame() %>%
  rownames_to_column('gene') %>%
  arrange(padj)

message("Writing DESeq2 non batch-corrected results")
data.table::fwrite(x = dge_output_nobatch,
                 file = file.path(
                   output_dir,
                   'deseq2_analysis',
                   paste0('DESeq2_noBatchC_', dataset, '_dge.tsv')
                 ), sep = '\t')

# plot and save p-value histogram
message("Saving p-value histogram")
p <- deseq2_pvals_histogram(
  res_df = dge_output_nobatch,
  xlab = 'DGE RLE nbinomWaldTest p-value',
  ylab = 'Gene count',
  title = paste0('Histogram of DESeq2 nbinomWaldTest p-values')
)
filename <- file.path(plots_dir, 'dge_deseq2_histogram.pdf')
ggsave(
  filename = filename,
  plot = p,
  width = 8,
  height = 7,
  bg = "white"
)

print("DESeq2 analysis finished.")

# Create appended list objects from deseq2 and dge output
dfs.ruvseq <- ruvg_out[["ruvg_eset"]]
dfs.dge <- ruvg_out[["dge_output"]]

# rm(ruvg_out)

# Filter to positive and negative control gene sets
dfs.dge <- lapply(dfs.dge, function(x) {
  x <- as.data.frame(x)
})

dfs.dge.filt <- lapply(dfs.dge, function(x) {
  dplyr::filter(.data = x, gene %in% pos_neg_ctrl_genes)
})

dge_output_nobatch <-
  dplyr::filter(.data = dge_output_nobatch, gene %in% pos_neg_ctrl_genes)

# Set to data frame and order by gene
dfs.dge.filt <- lapply(dfs.dge.filt, function(x) {
  setDT(x)
  setkey(x, cols = 'gene')
})

setDT(dge_output_nobatch)
setkey(dge_output_nobatch, cols = 'gene')

# Identify ruvseq analysis with optimal sensitivity/specificity
dfs.dge.filt <- lapply(dfs.dge.filt, function(x) {
  x <- x[, c('p_val_diff') := padj - dge_output_nobatch$padj]
})

pos.ctrl.counts <- sapply(dfs.dge.filt, function(x) {
  nrow(x[(p_val_diff < 0) & (gene %in% pos_ctrl_genes)])
})

neg.ctrl.counts <- sapply(dfs.dge.filt, function(x) {
  nrow(x[(p_val_diff > 0) & (gene %in% neg_ctrl_genes)])
})

scores <- c()
for (i in seq_along(pos.ctrl.counts)) {
  ratios <- na.omit(neg.ctrl.counts / pos.ctrl.counts)
  if (any(ratios < 0.01) | any(ratios > 100)) {
    scores[i] <-
      exp(mean(log(
        c(pos.ctrl.counts[i], neg.ctrl.counts[i])
      )))
  } else
    (scores[i] = mean(c(pos.ctrl.counts[i], neg.ctrl.counts[i])))
}

# Retrieve index of max score and corresponding ruvg analysis
scores.ind <- which.max(scores)
ruvg.dge <- dfs.dge[[scores.ind]]
ruvg.res <- dfs.ruvseq[[scores.ind]]

# create new expression set and run umap
seq_expr_set_raw <-
  EDASeq::newSeqExpressionSet(
    counts = round(ruvg.res@assayData$counts),
    phenoData = data.frame(bs_id, molecular_subtype, RNA_library, row.names = colnames(round(
      ruvg.res@assayData$counts
    )))
  )

seq_expr_set_norm <-
  EDASeq::newSeqExpressionSet(
    counts = round(ruvg.res@assayData$normalizedCounts),
    phenoData = data.frame(bs_id, molecular_subtype, RNA_library, row.names = colnames(
      round(ruvg.res@assayData$normalizedCounts)
    ))
  )

umap_raw <-
  edaseq_plot(
    object = seq_expr_set_raw,
    title = "Before RUVg normalization",
    type = "UMAP",
    color_var = "RNA_library",
    shape_var = "RNA_library"
  )

umap_norm <-
  edaseq_plot(
    object = seq_expr_set_norm,
    title = "After RUVg normalization",
    type = "UMAP",
    color_var = "RNA_library",
    shape_var = "RNA_library"
  )

umap_raw_subtype <-
  edaseq_plot(
    object = seq_expr_set_raw,
    title = "Before RUVg normalization",
    type = "UMAP",
    color_var = "molecular_subtype",
    shape_var = "molecular_subtype"
  )

umap_norm_subtype <-
  edaseq_plot(
    object = seq_expr_set_norm,
    title = "After RUVg normalization",
    type = "UMAP",
    color_var = "molecular_subtype",
    shape_var = "molecular_subtype"
  )

# save both UMAPs in a single file
p <-
  ggpubr::ggarrange(
    umap_raw,
    umap_norm,
    umap_raw_subtype,
    umap_norm_subtype,
    common.legend = F,
    legend = "bottom"
  )
fname <-
  file.path(plots_dir,
            'final_clustering_with_and_without_norm_rna_lib.pdf')
ggsave(
  filename = fname,
  plot = p,
  width = 6,
  height = 6,
  device = "pdf",
  bg = "white"
)



# plot and save p-value histogram for optimal ruvseq result
p <- deseq2_pvals_histogram(
  res_df = ruvg.dge,
  xlab = 'DGE optimal RUVseq nbinomWaldTest p-value',
  ylab = 'Gene count',
  title = paste0('Histogram of DESeq2 nbinomWaldTest p-values post RUVseq')
)
filename <-
  file.path(plots_dir, 'dge_deseq2_ruvseq_optimal_histogram.pdf')
ggsave(
  filename = filename,
  plot = p,
  width = 8,
  height = 7,
  bg = "white"
)

# Return normalized counts

saveRDS(ruvg.res@assayData$normalizedCounts,
                 file = file.path(
                   norm_count_dir,
                   paste0('RUVg_optimal_k', scores.ind, '_normalized_counts.rds')
                 ))

# Return corresponding DGE analysis
data.table::fwrite(ruvg.dge,
                 file = file.path(
                   output_dir, 'deseq2_analysis',
                   paste0('RUVg_optimal_k', scores.ind, '_dgeResults.tsv')
                 ), sep = '\t')
message('Done')
