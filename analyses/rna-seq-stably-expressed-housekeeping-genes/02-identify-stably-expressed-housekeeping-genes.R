suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(edgeR))


#------------ Create output directories ----------------------------------------
norm_method <- 'tmm'
table_outdir <- file.path('results', paste0(norm_method, '_normalized'))
dir.create(table_outdir, showWarnings = FALSE)

plot_outdir <- file.path('plots', paste0(norm_method, '_normalized'))
dir.create(plot_outdir, showWarnings = FALSE)


#------------ Read prepared data -----------------------------------------------
m_cnt_df <- readRDS(
    '../../scratch/pbta_kf_gtex_target_tcga_rsem_expected_cnt_df.rds')

m_kfbid_sid_htl_df <- readRDS(
    '../../scratch/pbta_kf_gtex_target_tcga_histology_df.rds')


#------------ Select samples for DGE -------------------------------------------
sh_rmna_m_kfbid_sid_htl_df <- m_kfbid_sid_htl_df[
    !is.na(m_kfbid_sid_htl_df$short_histology), ]

nbl_sids <- sh_rmna_m_kfbid_sid_htl_df[
    sh_rmna_m_kfbid_sid_htl_df$short_histology == 'NBL',
    'sample_id']

gtex_sids <- m_kfbid_sid_htl_df[
    substr(m_kfbid_sid_htl_df$sample_barcode, 1, 5) == 'GTEX-',
    'sample_id']

counts <- cbind(
    m_cnt_df[, nbl_sids],
    m_cnt_df[, gtex_sids]
)
stopifnot(identical(colnames(counts),
                    unique(colnames(counts))))

# defein group for DGE testing
group <- factor(c(rep("NBL", length(nbl_sids)),
                  rep("GTEX", length(gtex_sids))),
                levels = c('GTEX', 'NBL'))

# Make design matrix 
design <- model.matrix(~group)

### build normalized DGEList
counts_object <- DGEList(counts = counts, group = group)

counts_object <- counts_object[
    filterByExpr(counts_object), , keep.lib.sizes=FALSE]

counts_object <- calcNormFactors(counts_object, method = "TMM")
norm_cnt_mat <- cpm(counts_object)

# read and select housekeeping genes
hkgenes <- read.csv(file.path('input', 'Housekeeping_GenesHuman.csv'),
                    sep = ";", stringsAsFactors = FALSE)
hkgenes <- unique(hkgenes$Gene.name)
hkgenes <- intersect(rownames(counts_object), hkgenes)
counts_object <- counts_object[hkgenes, ]

plot_nm_str <- 'TMM'

counts_object <- estimateDisp(
    counts_object, design=design, prior.df=NULL, trend.method='locfit',
    tagwise=TRUE)

png(file.path(plot_outdir, 'estimated_dispersions.png'))
plotBCV(counts_object)
n_null_dev <- dev.off()


#------------ Run LRT ----------------------------------------------------------
print(paste0('Run differential gene expression LRT on',
             ' NBL vs GTEX RNA-seq...'))

glm_fit <- glmFit(counts_object, design)
lrt <- glmLRT(glm_fit)

# Save LRT p-value table and histogram
lrt_top_tags <- topTags(lrt, adjust.method = "BH", n = Inf)
lrt_out_df <- lrt_top_tags$table
stopifnot(identical(colnames(lrt_out_df),
                    c("logFC", "logCPM", "LR", "PValue", "FDR")))

lrt_out_df <- lrt_out_df[order(-lrt_out_df$PValue), ]
colnames(lrt_out_df) <- c("NBL_over_GTEX_logFC",
                          "average_logCPM", "LR", "PValue", "BH FDR")
write.csv(lrt_out_df, file=file.path(table_outdir,
                                     'NBL_vs_GTEX_dge_lrt_res.csv'))

# plot and save p-value histogram
p <- ggplot(lrt_top_tags$table, aes(x=PValue)) +
    geom_histogram(binwidth = 0.05, center = 0.025) +
    theme_classic() +
    scale_x_continuous(expand = expand_scale(mult = c(0, 0.02))) +
    scale_y_continuous(expand = expand_scale(mult = c(0, 0.05))) +
    xlab(paste0('NBL vs GTEX RNA-seq DGE ', plot_nm_str,
                ' LRT p-value')) +
    ylab('Gene count') +
    ggtitle(paste0('Histogram of NBL vs GTEX RNA-seq\n',
                   'differential gene expression ', plot_nm_str,
                   ' normalized\n',
                   'LRT p-values\n',
                   sum(lrt_top_tags$table$PValue < 0.05),
                   ' genes have p-value < 0.05\n',
                   sum(lrt_top_tags$table$PValue >= 0.05),
                   ' genes have p-value >= 0.05\n',
                   sum(lrt_top_tags$table$FDR < 0.05),
                   ' genes have BH FDR < 0.05\n',
                   sum(lrt_top_tags$table$FDR >= 0.05),
                   ' genes have BH FDR >= 0.05')) +
    theme(text = element_text(size=15))

ggsave(file.path(plot_outdir, 'NBL_vs_GTEX_dge_lrt_pvals_histogram.png'),
       dpi = 300, plot = p, width = 8, height = 7)

# plot and save count boxplot
get_ge_boxplot <- function(gid, norm_cnt_mat, histology, plot_cnt_type) {
    stopifnot(identical(length(gid), as.integer(1)))
    stopifnot(is.character(gid))
    plot_df <- data.frame(norm_cnt_mat[gid, ])
    # wide to long
    plot_df <- gather(plot_df)
    plot_df$histology <- histology
    
    p <- plot_df %>%
        ggplot(aes(histology, value)) +
        geom_boxplot(outlier.shape=NA) +
        geom_point(position = position_jitter(seed = 17), alpha = 0.1) +
        theme(legend.position = "none") +
        xlab('Histology') +
        ylab('Normalized read count') +
        ggtitle(paste0(gid, plot_cnt_type)) +
        theme_classic() +
        theme(text = element_text(size=15))
    return(p)
}

seg_plot_outdir <- file.path(plot_outdir,
                             'stably_exp_hk_gene_norm_cnt_boxplot')
dir.create(seg_plot_outdir, showWarnings = FALSE)

res <- sapply(1:30, function(i) {
    gid <- rownames(lrt_out_df)[i]
    stopifnot(identical(colnames(norm_cnt_mat),
                        rownames(counts_object$samples)))
    p <- get_ge_boxplot(gid, norm_cnt_mat, counts_object$samples$group,
                        '\nTMM normalized CPM')
    ggsave(file.path(seg_plot_outdir,
                     paste0(gid, 
                            '_normalized_count_boxplot.png')),
           dpi = 300, plot = p, width = 5, height = 5)
    return(TRUE)
})
print('Done.')
