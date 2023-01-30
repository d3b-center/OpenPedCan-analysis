deseq2_pvals_histogram <- function(res_df, xlab, ylab, title) {
  stopifnot(all(c('pvalue', 'padj') %in% colnames(res_df)))
  
  # basic histogram without density
  p <- ggplot(res_df, aes(x = pvalue)) +
      geom_histogram(binwidth = 0.05, center = 0.025) +
      ggpubr::theme_pubr() +
      scale_x_continuous(expand = expand_scale(mult = c(0, 0.02))) +
      scale_y_continuous(expand = expand_scale(mult = c(0, 0.05))) +
      xlab(xlab) +
      ylab(ylab) + ggtitle(paste0(title, '\n',
                   'Total number of genes: ', nrow(res_df), '\n', 
                   sum(res_df$pvalue < 0.05),
                   ' genes have p-value < 0.05\n',
                   sum(res_df$pvalue >= 0.05),
                   ' genes have p-value >= 0.05\n',
                   sum(res_df$padj < 0.05),
                   ' genes have BH FDR < 0.05\n',
                   sum(res_df$padj >= 0.05),
                   ' genes have BH FDR >= 0.05'))
  return(p)
}