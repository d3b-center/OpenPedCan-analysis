suppressPackageStartupMessages({
  library(ggplot2)
  library(ggpubr)
  library(EDASeq)
})

# create boxplot 
box_plots <- function(object, isLog = F, title = "", facet_var, color_var){
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
    y_lab <- "log2(counts)"
  } else {
    Y <- apply(counts, 1, function(y) scale(y, center=TRUE, scale=FALSE))
    y_lab <- "counts"
  }
  
  # assign rownames
  rownames(Y) <- colnames(counts)
  
  # assemble the data for the plot
  Y <- reshape2::melt(as.matrix(Y), varnames = c("bs_id","gene"), value.name = "expr")
  Y$bs_id <- gsub("TARGET-[0-9]{2}-", "", Y$bs_id)
  d <- object@phenoData@data %>%
    inner_join(Y, by = "bs_id")
  
  # plot
  p <- ggplot(data = d, aes_string(x = "bs_id", y = "expr", color = color_var)) + 
    stat_boxplot(geom ='errorbar', width = 0.2) +
    geom_boxplot(lwd = 0.5, fatten = 0.7, outlier.shape = 1, width = 0.5, outlier.size = 1) + 
    ggpubr::theme_pubr(base_size = 8) +
    xlab("") + ylab(y_lab) + theme(axis.text.x = element_text(size = 4, angle = 30, hjust = 1, vjust = 1)) +
    facet_wrap(~get(facet_var), scales = "free", nrow = 1) +
    ggtitle(title) + theme(legend.position = "bottom")
  
  return(p)
}
