# In this script we will be gathering pathology diagnosis
# and pathology free text diagnosis terms to select chordoma
# samples for following chordoma subtyping analysis and save 
# the json file in chordoma-subset folder

library(tidyverse)

## Directories

root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

output_dir <- file.path(root_dir,
                        "analyses",
                        "molecular-subtyping-chordoma",
                        "chordoma-subset")
if(!dir.exists(output_dir)){
  dir.create(output_dir)
}

output_file <- file.path(output_dir, "chordoma_subtyping_path_dx_strings.json")                         

## The `pathology_diagnosis` fields for chordoma
exact_path_dx <- "Chordoma"

## Create a list with the strings we'll use for inclusion
term_list <- list(exact_path_dx = exact_path_dx)

# Save the list as json
writeLines(jsonlite::prettify(jsonlite::toJSON(term_list)), output_file)
