# In this script we will be gathering pathology diagnosis
# and pathology free text diagnosis terms to select pineoblastoma (PB)
# samples for following PB subtyping analysis and save 
# the json file in PB-subset folder

library(tidyverse)

## Directories

root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

output_dir <- file.path(root_dir,
                        "analyses",
                        "molecular-subtyping-PB",
                        "PB-subset")
if(!dir.exists(output_dir)){
  dir.create(output_dir)
}

output_file <- file.path(output_dir, "PB_subtyping_path_dx_strings.json")                         

## Read histologies file
histo <- readr::read_tsv(file.path(root_dir, "data", "histologies-base.tsv")) 

## the path dx and path free text is based on the methylation subypes:  
##  "PB_FOXR2", "PB_GRP1A", "PB_GRP1B", "PB_GRP2", "PIN_RB"
## The `pathology_diagnosis` fields for PB
exact_path_dx <- "Pineoblastoma"

## The `pathology_diagnosis` fields for PB
path_free_text_exact <- unique(histo$pathology_free_text_diagnosis[
  grepl("pineoblastoma", histo$pathology_free_text_diagnosis, ignore.case = TRUE)], )

## Create a list with the strings we'll use for inclusion
term_list <- list(exact_path_dx = exact_path_dx,
                  path_free_text_exact = path_free_text_exact)

# Save the list as json
writeLines(jsonlite::prettify(jsonlite::toJSON(term_list)), output_file)
