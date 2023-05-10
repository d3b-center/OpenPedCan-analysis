# In this script we will be gathering pathology diagnosis
# and pathology free text diagnosis terms to select CRANIO
# samples for following CRANIO subtyping analysis and save 
# the json file in CRANIO-subset folder

library(tidyverse)

## Directories

root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

output_dir <- file.path(root_dir,
                        "analyses",
                        "molecular-subtyping-CRANIO",
                        "cranio-subset")
if(!dir.exists(output_dir)){
  dir.create(output_dir)
}

output_file <- file.path(output_dir, "CRANO_subtyping_path_dx_strings.json")                         

## Read histologies file
histo <- readr::read_tsv(file.path(root_dir, "data", "histologies-base.tsv")) 

## The `pathology_diagnosis` fields for CRANIO
exact_path_dx <- "Craniopharyngioma"


path_free_text_exact <- histo %>% 
  filter(pathology_diagnosis == exact_path_dx) %>%
  pull(pathology_free_text_diagnosis) %>% 
  unique()

## Create a list with the strings we'll use for inclusion
term_list <- list(exact_path_dx = exact_path_dx, 
                  path_free_text_exact = path_free_text_exact)

# Save the list as json
writeLines(jsonlite::prettify(jsonlite::toJSON(term_list)), output_file)

