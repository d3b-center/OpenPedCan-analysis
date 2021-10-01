# base directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git")) 
data_dir <- file.path(root_dir, "data")
analysis_dir <- file.path(root_dir, "analyses", "tp53_nf1_score")

# source function to plot ROC curve
source(file.path(analysis_dir, "util", "plot_roc.R"))

# output directories
plots_dir <- file.path(analysis_dir, "plots")
results_dir <- file.path(analysis_dir, "results")

# read data obtained from 06-evaluate-classifier.py
histology_df <- readr::read_tsv(file.path(data_dir, "histologies.tsv"), guess_max = 100000)
rna_library_list <- histology_df %>% 
  filter(sample_type == "Tumor") %>% 
  filter(!is.na(RNA_library)) %>% 
  pull(RNA_library) %>% unique()

for (i in 1:length(rna_library_list)){
  
  rna_library <- rna_library_list[i] %>% gsub(" ", "_")
  
  roc_file <- readr::read_tsv(file.path(results_dir, paste0(rna_library, "_TP53_roc_threshold_results.tsv")))
  roc_file_shuff <- readr::read_tsv(file.path(results_dir, paste0(rna_library, "_TP53_roc_threshold_results_shuffled.tsv")))
  
  # call function to plot ROC curve
  plot_roc(roc_df =  roc_file %>%
             rbind(roc_file_shuff), plots_dir, fname = paste0(rna_library, "_TP53_roc.png"))
}
