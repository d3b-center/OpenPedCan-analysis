# adapted from https://github.com/drisso/EDASeq/blob/master/R/methods-SeqExpressionSet.R 
# modified to use ggplot2 instead of base R
suppressPackageStartupMessages({
  library(ggplot2)
  library(ggpubr)
  library(uwot)
  library(EDASeq)
})

# create clustering using PCA or UMAP 
edaseq_plot <- function(object, isLog = F, title = "", type = c("PCA", "UMAP"), color_var, shape_var){
  if(ncol(EDASeq::counts(object)) <= 1){
    stop("At least two samples needed for the PCA plot.")
  } else {
    if(all(is.na(EDASeq::normCounts(object)))) {
      print("use raw counts")
      counts <- EDASeq::counts(object)
    } else {
      print("use norm counts")
      counts <- EDASeq::normCounts(object)
    }
  }
  
  if(!isLog) {
    Y <- apply(log(counts+1), 1, function(y) scale(y, center=TRUE, scale=FALSE))
  } else {
    Y <- apply(counts, 1, function(y) scale(y, center=TRUE, scale=FALSE))
  }
  
  # assign rownames
  rownames(Y) <- colnames(counts)
  s <- svd(Y)
  percent <- s$d^2/sum(s$d^2)*100
  labs <- sapply(seq_along(percent), function(i) {
    paste("PC ", i, " (", round(percent[i], 2), "%)", sep="")
  })
  
  # assembly the data for the plot
  if(type == "PCA"){
    d <- data.frame(PC1=s$u[,1], PC2=s$u[,2], object@phenoData@data)
    p <- ggplot(data=d, aes_string(x="PC1", y="PC2", color = color_var, shape = shape_var)) + 
      geom_point(size = 3) + 
      #geom_text(label = bs_id, size = 1, color = "black") +
      ggpubr::theme_pubr(base_size = 8) +
      xlab(paste0("PC1: ",round(percent[1]),"% variance")) +
      ylab(paste0("PC2: ",round(percent[2]),"% variance")) +
      ggtitle(title) + theme(legend.position = "bottom") +
      guides(color = "none")
  } else if(type == "UMAP"){
    set.seed(100)
    umap_out <- uwot::umap(X = t(counts), n_neighbors = ncol(counts) - 1, n_sgd_threads = 1)
    d <- data.frame(UMAP1=umap_out[,1], UMAP2=umap_out[,2], object@phenoData@data)
    p <- ggplot(data = d, aes_string(x="UMAP1", y="UMAP2", color = color_var, shape = shape_var)) + 
      geom_point(size = 3) + 
      #geom_text(label = bs_id, size = 1, color = "black") +
      ggpubr::theme_pubr(base_size = 8) +
      ggtitle(title) + theme(legend.position = "bottom") +
      guides(color = "none")
  }
  
  return(p)
}
