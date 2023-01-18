# function to create density plot
suppressPackageStartupMessages(library(ggplot2))
density_plot <- function(mat, color_var, title, xlab){
  p <- ggplot(mat, aes_string(x = 'log2(value + 1)', fill = color_var)) + 
    geom_density(alpha = .3) +
    theme_bw() + theme_Publication2() +
    ggtitle(title) +
    xlab(xlab)
  return(p)
}