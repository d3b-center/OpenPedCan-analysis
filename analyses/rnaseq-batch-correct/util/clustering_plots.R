# function to create clustering plot using either umap or t-SNE 
suppressPackageStartupMessages(library(uwot))
suppressPackageStartupMessages(library(Rtsne))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(irlba))
suppressPackageStartupMessages(library(tidyverse))

clustering_plot <- function(mat, metadata, color_var, shape_var, title, type = c("umap", "tsne")){
  # set seed for reproducibility
  set.seed(100) 
  
  if(type == "umap"){
    umap_out <- uwot::umap(X = t(log2(mat + 1)), n_components = 2, metric = "correlation", n_sgd_threads = 100L)
    
    # add colnames/rownames
    colnames(umap_out) <- c("Dim1", "Dim2")
    rownames(umap_out) <- colnames(mat)
    
    # add metadata
    dat <- umap_out %>%
      as.data.frame() %>%
      rownames_to_column('tmp')  %>%
      inner_join(metadata %>%
                   rownames_to_column('tmp'), by = 'tmp') %>%
      column_to_rownames('tmp')
  } else if(type == "tsne"){
    # use partial_pca for faster plots
    tsneOut <- Rtsne(t(log2(mat + 1)), initial_dims = 2, dims = 2, check_duplicates = FALSE, theta = 0, max_iter = 500, partial_pca = TRUE)
    colnames(tsneOut) <- c("Dim1", "Dim2")
    dat <- data.frame(tsneOut$Y, metadata)
  }
  
  # plot
  p <- ggplot(dat, aes_string('Dim1', 'Dim2', fill = color_var, shape = shape_var)) +
    geom_jitter(size = 3, width = 0.5, height = 0.5, alpha = 0.5) +
    theme_bw() + theme_Publication2() + ggtitle(title) +
    scale_shape_manual(values = 1:length(unique(dat[,shape_var])) + 20) +
    guides(fill = guide_legend(override.aes = list(shape = 21))) +
    theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 8)) 
  
  return(p)
}