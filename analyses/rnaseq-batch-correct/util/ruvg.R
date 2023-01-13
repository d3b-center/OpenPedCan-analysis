# function to evaluate RUVg: Estimating the factors of unwanted variation using control genes
# uses negative control genes, assumed to have constant expression across samples
# Authors: Komal Rathi, updated by Adam Kraya

ruvg_test <-
  function(seq_expr_set,
           emp_neg_ctrl_genes,
           k_val = 1:2,
           prefix,
           diff_type = "deseq2",
           output_dir,
           plot_dir,
           design_variable,
           color_var,
           shape_var,
           drop = 0) {
    # create output directory
    output_dir <- file.path(output_dir, "deseq2_analysis")
    dir.create(output_dir, showWarnings = F, recursive = T)
    
    # to estimate the factors of unwanted variation,
    # subset to negative control genes (genes that can be assumed not to be influenced by the covariates of interest)
    emp_neg_ctrl_genes <-
      intersect(emp_neg_ctrl_genes,
                rownames(seq_expr_set@assayData$counts))
    emp_neg_ctrl_genes <-
      emp_neg_ctrl_genes[emp_neg_ctrl_genes %in% rownames(seq_expr_set@assayData$counts)]
    print(paste(
      "Number of negative control genes:",
      length(emp_neg_ctrl_genes)
    ))
    
    # if no genes left in emp_neg_ctrl_genes, then don't run function
    if (length(emp_neg_ctrl_genes) == 0) {
      return(NULL)
    }
    
    # if length of emp_neg_ctrl_genes is less than k_val but greater than 0, then set max k_val number of genes
    if (length(emp_neg_ctrl_genes) < max(k_val)) {
      k_val <- c(1:length(emp_neg_ctrl_genes))
    }
    
    # pca and umap before ruvg
    ruvg_pca <-
      edaseq_plot(
        object = seq_expr_set,
        title = paste0("PCA: Expected counts prior to RUVg", "(d=", drop, ")"),
        type = "PCA",
        color_var = color_var,
        shape_var = shape_var
      )
    ruvg_umap <-
      edaseq_plot(
        object = seq_expr_set,
        title = paste0("UMAP: Expected counts prior to RUVg", "(d=", drop, ")"),
        type = "UMAP",
        color_var = color_var,
        shape_var = shape_var
      )
    cluster_plot <-
      ggpubr::ggarrange(ruvg_pca,
                        ruvg_umap,
                        common.legend = T,
                        legend = "bottom")
    # clustering output (PCA/UMAP)
    pdf(
      file = file.path(
        plot_dir,
        paste0(prefix, '_preRUVg_', diff_type , '_', drop, '_clustering.pdf')
      ),
      width = 6,
      height = 4
    )
    print(cluster_plot)
    dev.off()
    
    # loop through all Ks
    cluster_plot <- list()
    pval_hist_plot <- list()
    pval_hist_plot_subset <- list()
    dge_output_neg_control_genes <- list()
    chisq_out <- list()
    ks_out <- list()
    dge_output_list <- list()
    ruvseq_set_list <- list()
    for (i in 1:length(k_val)) {
      print(paste0("K = ", i))
      print(paste0('Run RUVg...'))
      
      # run RUVg assuming there are k_val factors of unwanted variation
      ruvg_set <-
        RUVg(
          x = seq_expr_set,
          cIdx = emp_neg_ctrl_genes,
          k = k_val[i],
          drop = drop
        )
      ruvseq_set_list[[i]] <- ruvg_set
      
      # pca and umap after ruvg
      ruvg_pca <-
        edaseq_plot(
          object = ruvg_set,
          title = paste0("PCA: RUVg output (k = ", i, ", d=", drop, ")"),
          type = "PCA",
          color_var = color_var,
          shape_var = shape_var
        )
      ruvg_umap <-
        edaseq_plot(
          object = ruvg_set,
          title = paste0("UMAP: RUVg output (k = ", i, ", d=", drop, ")"),
          type = "UMAP",
          color_var = color_var,
          shape_var = shape_var
        )
      cluster_plot[[i]] <-
        ggpubr::ggarrange(ruvg_pca,
                          ruvg_umap,
                          common.legend = T,
                          legend = "bottom")
      
      # differential expression after RUVg
      # W_i corresponds to the factors of "unwanted variation"
      # factor for unwanted variation comes first for deseq2
      design <-
        model.matrix(as.formula(paste0('~ W_', i, '+' , design_variable)), data = pData(ruvg_set))
      ruv_dds <-
        DESeq2::DESeqDataSetFromMatrix(
          countData = counts(ruvg_set),
          colData = pData(ruvg_set),
          design = design
        )
      ruv_dds <- DESeq2::DESeq(ruv_dds)
      
      # Export results and save as CSV
      dge_output <-
        DESeq2::results(ruv_dds,
                        cooksCutoff = FALSE,
                        pAdjustMethod = 'BH')
      dge_output <- dge_output %>%
        as.data.frame() %>%
        rownames_to_column('gene') %>%
        arrange(padj)
      
      dge_output_list[[i]] <- dge_output
      
      # plot and save p-value histogram
      # evaluate the distribution of p-values for full transcriptome
      pval_hist_plot[[i]] <-
        deseq2_pvals_histogram(
          res_df = dge_output,
          xlab = 'RUVg p-value (full transcriptome)',
          ylab = 'Gene count',
          title = paste0('Histogram (k = ', i, ', d=', drop, ')')
        )
      
      # test for uniformity (negative control genes only)
      dge_output_neg_control_genes[[i]] <- dge_output %>%
        filter(gene %in% emp_neg_ctrl_genes)
      
      # evaluate the distribution of p-values
      pval_hist_plot_subset[[i]] <-
        deseq2_pvals_histogram(
          res_df = dge_output_neg_control_genes[[i]],
          xlab = 'RUVr p-value (negative control genes)',
          ylab = 'Gene count',
          title = paste0('Histogram (k = ', i, ', d=', drop, ')')
        )
      
      # chisq test for p-values
      chisq_out[[i]] <-
        chisq.test(x = dge_output_neg_control_genes[[i]]$pvalue)
      chisq_out[[i]] <- broom::tidy(chisq_out[[i]])
      chisq_out[[i]]$k <- k_val[i]
      
      # ks test for p-values
      ks_out[[i]] <-
        ks.test(x = dge_output_neg_control_genes[[i]]$pvalue, punif)
      ks_out[[i]] <- broom::tidy(ks_out[[i]])
      ks_out[[i]]$k <- k_val[i]
    }
    
    pdf(
      file = file.path(
        plot_dir,
        paste0(
          prefix,
          '_dge_ruvg_',
          diff_type,
          '_d',
          drop,
          '_clustering.pdf'
        )
      ),
      width = 6,
      height = 4
    )
    print(cluster_plot)
    dev.off()
    
    # p-value histogram (full transcriptome)
    pdf(
      file = file.path(
        plot_dir,
        paste0(
          prefix,
          '_dge_ruvg_',
          diff_type,
          '_d',
          drop,
          '_histogram_full_transcriptome.pdf'
        )
      ),
      width = 8,
      height = 7
    )
    print(pval_hist_plot)
    dev.off()
    
    # p-value histogram (neg control genes)
    pdf(
      file = file.path(
        plot_dir,
        paste0(
          prefix,
          '_dge_ruvg_',
          diff_type,
          '_d',
          drop,
          '_histogram_controls.pdf'
        )
      ),
      width = 8,
      height = 7
    )
    print(pval_hist_plot_subset)
    dev.off()
    
    # rbind and save chisq values
    data.table::rbindlist(chisq_out) %>%
      data.table::fwrite(file = file.path(
        output_dir,
        paste0(
          prefix,
          '_dge_ruvg_',
          diff_type,
          '_d',
          drop,
          '_chisq_pvalues.tsv'
        )
      ), sep = '\t')
    
    # rbind and save ks values
    data.table::rbindlist(ks_out) %>%
      data.table::fwrite(file = file.path(
        output_dir,
        paste0(
          prefix,
          '_dge_ruvg_',
          diff_type,
          '_d',
          drop,
          '_ks_pvalues.tsv'
        )
      ), sep = '\t')
    
    output_list <-
      list(dge_output = dge_output_list, ruvg_eset = ruvseq_set_list)
    return(output_list)
  }