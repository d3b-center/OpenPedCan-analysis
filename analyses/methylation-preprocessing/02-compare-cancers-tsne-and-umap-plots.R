# Creates comparison methylation profiles t-SNE plots of selected cancer genes 
# for cancer types preprocessed from Illumina Infinium HumanMethylation450 
# BeadArrays

# Eric Wafula for Pediatric OpenTargets
# 01/05/2022

# Load libraries:
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(Rtsne))
suppressPackageStartupMessages(library(umap))
theme_set(theme_bw(18))

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module, metadata, results and plots directories
module_dir <- file.path(root_dir, "analyses", "methylation-analysis")
results_dir <- file.path(module_dir, "results")
metadata_dir <- file.path(module_dir, "metadata")
plots_dir <- file.path(module_dir, "plots")

# Create plots folder if it doesn't exist
if (!dir.exists(plots_dir)) {
  dir.create(plots_dir)
}

# Function to load, subset, and reformat methylation m-values
load_meth_table <- function(file_path) {
  cancer_types <- stringr::str_extract(
    stringr::str_extract(basename(file_path), "\\w+"), "\\D+")
  required_cols <- c("Sample_Name", "Probe", "Meth_Value","UCSC_RefGene_Name")
  meth_table <- data.table::fread(file_path, 
                                  select = required_cols, 
                                  showProgress = FALSE) %>% 
    tibble::tibble() %>% 
    # tidyr::separate_rows(UCSC_RefGene_Name, sep = ";", convert = FALSE) %>% 
    # dplyr::distinct() %>% 
    dplyr::mutate(Cancer_Type =
                    stringr::str_extract(cancer_types, "\\D+"))
  return(meth_table)
}

# Function to filter and transform methylation m-value for t-SNE plotting
filter_cancer_gene <- function(cancer_gene, meth_table) {
  gene_meth_table <- meth_table %>% 
    dplyr::filter(stringr::str_detect(UCSC_RefGene_Name, cancer_gene)) %>% 
    tidyr::separate_rows(UCSC_RefGene_Name, sep = ";", convert = FALSE) %>%
    dplyr::filter(stringr::str_detect(UCSC_RefGene_Name, cancer_gene)) %>%
    dplyr::select(-UCSC_RefGene_Name ) %>%
    dplyr::distinct() %>% 
    tidyr::pivot_wider(names_from = Probe, values_from = Meth_Value)
  return(gene_meth_table)
}


# Get gene symbols for cancer genes list
cancer_genes <- readr::read_csv(
  file.path(metadata_dir, "TARGET_Methylation_GeneList.txt"),
  show_col_types = FALSE) %>%
  dplyr::distinct() %>%
  dplyr::pull(Gene_Symbol)

# Processing methylation m-value for selected TARGET cancer genes
for (i in 1:length(cancer_genes)) {
  message("===============================================")
  message(c("Processing M-values for ", cancer_genes[i], " cancer gene..."))
  message("===============================================\n")
  # Normal
  message("Checking in  Normal (non-tumor) samples...\n")
  normal_meth_df <- load_meth_table(
    file.path(results_dir, "Normal-m-values-methylation.tsv.gz"))
  cancer_gene_df <- filter_cancer_gene(cancer_genes[i], normal_meth_df)
  rm(normal_meth_df)
  gc()

  # NBL
  message("Checking in  Neuroblastoma (NBL) samples...\n")
  nbl_meth_df <- load_meth_table(
    file.path(results_dir, "NBL-m-values-methylation.tsv.gz"))
  nbl_gene_df <- filter_cancer_gene(cancer_genes[i], nbl_meth_df)
  cancer_gene_df <- cancer_gene_df %>% dplyr::bind_rows(nbl_gene_df)
  rm(nbl_meth_df, nbl_gene_df)
  gc()

  # OS
  message("Checking in  Osteosarcoma (OS) samples...\n")
  os_meth_df <- load_meth_table(
    file.path(results_dir, "OS-m-values-methylation.tsv.gz"))
  os_gene_df <- filter_cancer_gene(cancer_genes[i], os_meth_df)
  cancer_gene_df <- cancer_gene_df %>% dplyr::bind_rows(os_gene_df)
  rm(os_meth_df, os_gene_df)
  gc()

  # CCSK
  message("Checking in  Clear Cell Sarcoma of the Kidney (CCSK) samples...\n")
  ccsk_meth_df <- load_meth_table(
    file.path(results_dir, "CCSK-m-values-methylation.tsv.gz"))
  ccsk_gene_df <- filter_cancer_gene(cancer_genes[i], ccsk_meth_df)
  cancer_gene_df <- cancer_gene_df %>% dplyr::bind_rows(ccsk_gene_df)
  rm(ccsk_meth_df, ccsk_gene_df)
  gc()

  # WT
  message("Checking in  Wilms Tumor (WT) samples...\n")
  wt_meth_df <- load_meth_table(
    file.path(results_dir, "WT-m-values-methylation.tsv.gz"))
  wt_gene_df <- filter_cancer_gene(cancer_genes[i], wt_meth_df)
  cancer_gene_df <- cancer_gene_df %>% dplyr::bind_rows(wt_gene_df)
  rm(wt_meth_df, wt_gene_df)
  gc()

  # AML
  message("Checking in Acute Myeloid Leukemia (AML) samples...\n")
  aml_meth_df <- load_meth_table(
    file.path(results_dir, "AML450k-m-values-methylation.tsv.gz"))
  aml_gene_df <- filter_cancer_gene(cancer_genes[i], aml_meth_df)
  cancer_gene_df <- cancer_gene_df %>% dplyr::bind_rows(aml_gene_df)
  rm(aml_meth_df, aml_gene_df)
  gc()
  
  if (length(cancer_gene_df$Sample_Name) > 0 ) {
    message(c("Creating comparative t-SNE plots for ", cancer_genes[i], 
              " gene...\n"))
    # write gene methylation matrix to file
    cancer_gene_df %>% data.table::setDT() %>%
      data.table::fwrite(file.path(plots_dir,
                                   paste0(cancer_genes[i], "-m-values.csv")))
    
    # create and save gene methylation t-SNE plot to file
    cancer_gene_df <- cancer_gene_df %>% tidyr::drop_na() %>% 
      dplyr::mutate(ID = dplyr::row_number())
    
    set.seed(142)
    tSNE_fit <- cancer_gene_df %>% 
      dplyr::select(where(is.numeric)) %>% 
      tibble::column_to_rownames("ID") %>% scale() %>% 
      Rtsne::Rtsne(perplexity = floor((nrow(cancer_gene_df) - 1) / 3), dims = 2)
    
    tSNE_df <- tSNE_fit$Y %>% as.data.frame() %>% 
      dplyr::rename(tSNE1="V1", tSNE2="V2") %>% 
      dplyr::mutate(ID=dplyr::row_number())
    
    tSNE_df <- tSNE_df %>% dplyr::inner_join(cancer_gene_df, by="ID")
    
    tSNE_df %>% ggplot2::ggplot(aes(x = tSNE1, y = tSNE2, 
                                    color = Cancer_Type,)) +
      ggplot2::geom_point()+
      ggplot2::theme(legend.position="right")+
      ggplot2::ggtitle(cancer_genes[i])+
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 15), 
            legend.text = ggplot2::element_text(size=10),
            legend.title = ggplot2::element_text(size=12),
            axis.title = ggplot2::element_text(size=12),
            axis.text = ggplot2::element_text(size=10))
    ggplot2::ggsave(file.path(plots_dir, paste0(cancer_genes[i], "-tsne-plot.png")))
    rm(tSNE_df)
    
    # create and save gene methylation UMAP plot to file
    UMAP_fit <- cancer_gene_df %>% 
      dplyr::select(where(is.numeric)) %>% 
      tibble::column_to_rownames("ID") %>% scale() %>%
      umap::umap()
    
    UMAP_df <- UMAP_fit$layout %>% as.data.frame() %>% 
      dplyr::rename(UMAP1="V1", UMAP2="V2") %>% 
      dplyr::mutate(ID=dplyr::row_number())
    
    UMAP_df <- UMAP_df %>% dplyr::inner_join(cancer_gene_df, by="ID")
    
    UMAP_df %>% ggplot2::ggplot(aes(x = UMAP1, y = UMAP2, 
                                    color = Cancer_Type,)) +
      ggplot2::geom_point()+
      ggplot2::theme(legend.position="right")+
      ggplot2::ggtitle(cancer_genes[i])+
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 15), 
                     legend.text = ggplot2::element_text(size=10),
                     legend.title = ggplot2::element_text(size=12),
                     axis.title = ggplot2::element_text(size=12),
                     axis.text = ggplot2::element_text(size=10))
    ggplot2::ggsave(file.path(plots_dir, paste0(cancer_genes[i], "-umap-plot.png")))
    rm(UMAP_df)
    
  } else {
    message(c("No methylation data found for ", cancer_genes[i], 
              " gene in all cancer types...\n")) 
    }
  rm(cancer_gene_df)
  gc()
}

message("\nAnalysis Done..\n")
