# In this script we will be gathering pathology diagnosis
# and pathology free text diagnosis terms to select EWS
# samples for following EWS subtyping analysis and save 
# the json file in EWS-subset folder

library(tidyverse)

## Directories

root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

output_dir <- file.path(root_dir,
                        "analyses",
                        "molecular-subtyping-EWS",
                        "ews-subset")
if(!dir.exists(output_dir)){
  dir.create(output_dir)
}

output_file <- file.path(output_dir, "EWS_subtyping_path_dx_strings.json")                         

## Read histologies file
histo <- readr::read_tsv(file.path(root_dir, "data", "histologies-base.tsv")) 

## The `pathology_diagnosis` fields for EWS
exact_path_dx <- "Ewings Sarcoma"

## Create a list with the strings we'll use for inclusion
term_list <- list(exact_path_dx = exact_path_dx)

# Save the list as json
writeLines(jsonlite::prettify(jsonlite::toJSON(term_list)), output_file)
