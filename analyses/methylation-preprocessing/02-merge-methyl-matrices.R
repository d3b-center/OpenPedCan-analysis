# Merges methylation beta-values, m-values, and cp-values matrices for 
# all pre-processed array datasets.

# Eric Wafula for Pediatric OpenTargets
# 09/29/2022

# Load libraries
suppressPackageStartupMessages(library(tidyverse))

# Magrittr pipe
`%>%` <- dplyr::`%>%`

# establish base dir
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Set path to module, data and results directories
module_dir <- file.path(root_dir, "analyses", "methylation-preprocessing")
results_dir <- file.path(module_dir, "results")

# Merge beta-values matrices from all datasets
message("===================================================================")
message(c("Merge beta-values matrices from all datasets"))
message("===================================================================\n")

# list all beta-values matrices to merge
matrices_to_merge <- list.files(results_dir, 
                            pattern = "-methyl-beta-values.rds",
                            full.names = TRUE)
if (length(matrices_to_merge) > 1) {
  # merge beta-value matrices
  message("- Writing merged beta-values matrices to methyl-beta-values.rds file...\n")
  purrr::map(matrices_to_merge, ~ readr::read_rds(.x)) %>% 
    purrr::reduce(dplyr::full_join, by = "Probe_ID") %>% 
    # add ".M" to TARGET methylation samples to avoid conflicts with WXS samples
    # should be commented off in subsequent runs which will not including target 
    # array datasets. 
    dplyr::rename_with(.fn = ~ paste0(., ".M"), 
                       .cols = starts_with("TARGET-")) %>%
    # write merged beta-values to file
    readr::write_rds(file.path(results_dir, "methyl-beta-values.rds"))
} else {
  # rename beta-values matrix file
  message("- Rename beta-values matrix to methyl-beta-values.rds file...\n")
  file.rename(matrices_to_merge[1], paste(results_dir, 
                                          "methyl-beta-values.rds", sep = "/"))
}

# Merge m-values matrices from all datasets
message("===================================================================")
message(c("Merge m-values matrices from all datasets"))
message("===================================================================\n")

# list all m-values matrices to merge
matrices_to_merge <- list.files(results_dir, 
                                pattern = "-methyl-m-values.rds",
                                full.names = TRUE)
if (length(matrices_to_merge) > 1) {
  message("- Writing merged m-values matrices to methyl-m-values.rds file...\n")
  # merge m-value matrices
  purrr::map(matrices_to_merge, ~ readr::read_rds(.x)) %>% 
    purrr::reduce(dplyr::full_join, by = "Probe_ID") %>% 
    # add ".M" to TARGET methylation samples to avoid conflicts with WXS samples
    # should be commented off in subsequent runs which will not including target 
    # array datasets. 
    dplyr::rename_with(.fn = ~ paste0(., ".M"), 
                       .cols = starts_with("TARGET-")) %>%
    # write merged m-values to file
    readr::write_rds(file.path(results_dir, "methyl-m-values.rds"))
} else {
  # rename m-values matrix file
  message("- Rename m-values matrix to methyl-m-values.rds file...\n")
  file.rename(matrices_to_merge[1], paste(results_dir, 
                                          "methyl-m-values.rds", sep = "/"))
}

# Merge cn-values matrices from all datasets
message("===================================================================")
message(c("Merge cn-values matrices from all datasets"))
message("===================================================================\n")

# list all cn-values matrices to merge
matrices_to_merge <- list.files(results_dir, 
                                pattern = "-methyl-cn-values.rds",
                                full.names = TRUE)
if (length(matrices_to_merge) > 1) {
  # merge cn-value matrices
  message("- Writing merged cn-values matrices to methyl-cn-values.rds file...\n")
  purrr::map(matrices_to_merge, ~ readr::read_rds(.x)) %>% 
    purrr::reduce(dplyr::full_join, by = "Probe_ID") %>% 
    # add ".M" to TARGET methylation samples to avoid conflicts with WXS samples
    # should be commented off in subsequent runs which will not including target 
    # array datasets. 
    dplyr::rename_with(.fn = ~ paste0(., ".M"), 
                       .cols = starts_with("TARGET-")) %>%
    # write merged cn-values to file
    readr::write_rds(file.path(results_dir, "methyl-cn-values.rds"))
} else {
  # rename cn-values matrix file
  message("- Rename cn-values matrix to methyl-cn-values.rds file...\n")
  file.rename(matrices_to_merge[1], paste(results_dir, 
                                          "methyl-cn-values.rds", sep = "/"))
}
