# script to visualize the UMAP results from 01-full_dataset_compute_umap_umap_counts.R

# load libraries
suppressPackageStartupMessages({
  library(ggplot2)
  library(tidyverse)
  library(ggpubr)
})

# generalized function to call for plotting
plot_data <- function(umap_output, title = "", color_var, shape_var, label_var = NULL){
  
  # first two components explain majority of the variation 
  umap_output_for_plot <- readr::read_tsv('../../data/v11/histologies.tsv') %>%
    dplyr::select(Kids_First_Biospecimen_ID, Kids_First_Participant_ID, sample_id, sample_type, cohort, RNA_library, cancer_group, gtex_group, composition, harmonized_diagnosis) %>%
    inner_join(umap_output %>%
                 as.data.frame() %>%
                 rownames_to_column('Kids_First_Biospecimen_ID')) %>% 
    mutate(label = paste0(cohort, "_", RNA_library),
           label2 = paste0(cohort, "_", composition),
           group = ifelse(cohort == "GTEx", gtex_group, cancer_group))
  
  # plot
  plot_out <- ggplot(umap_output_for_plot, 
                     aes(UMAP1, UMAP2, color = get(color_var),
                         shape = get(shape_var),
                         text = paste0("Sample type:", sample_type,
                                       "\nGroup:", group,
                                       "\nID:", sample_id))) +
    geom_point(size = 2, alpha = 0.5) +
    ggtitle(title) +
    ggpubr::theme_pubr() +
    guides(color=guide_legend(title=color_var),
           shape=guide_legend(title=shape_var))
  
  if(!is.null(label_var)){
    plot_out <- plot_out +
      ggrepel::geom_text_repel(aes(label = get(label_var)), size = 2, show.legend = FALSE) 
  }
  
  return(plot_out)
}