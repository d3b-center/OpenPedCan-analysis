# In this script we will be gathering pathology diagnosis
# terms to select NBL samples for downstream NBL subtyping 
# analysis and save the json file in nbl-subset folder

# Detect the ".git" folder -- this will in the project root directory.
# Use this as the root directory to ensure proper sourcing of functions no
# matter where this is called from
library(tidyverse)

root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
                         
output_file <- file.path(root_dir,
                         "analyses",
                         "molecular-subtyping-NBL",
                         "nbl-subset",
                         "nbl_subtyping_path_dx_strings.json")

hist <- read_tsv(file.path(root_dir, "data", "histologies-base.tsv"), 
                 guess_max = 100000)

# The `pathology_diagnosis` fields for NBL
dx_terms <- hist %>%
  filter(grepl("neuroblastoma|Neuroblastoma", pathology_diagnosis)) %>%
  pull(pathology_diagnosis) %>%
  unique()


# Create a list with the strings we'll use for inclusion.
terms_list <- list(exact_path_dx = dx_terms)


# Save this list as JSON.
writeLines(jsonlite::prettify(jsonlite::toJSON(terms_list)), output_file)
