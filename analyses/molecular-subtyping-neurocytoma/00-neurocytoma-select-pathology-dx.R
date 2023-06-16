# In this script we will be gathering pathology diagnosis
# and pathology free text diagnosis terms to select HGG
# samples for downstream HGG subtyping analysis and save 
# the json file in hgg-subset folder

library(tidyverse)

# Detect the ".git" folder -- this will in the project root directory.
# Use this as the root directory to ensure proper sourcing of functions no
# matter where this is called from
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

output_dir <- file.path(root_dir,
                         "analyses",
                         "molecular-subtyping-neurocytoma",
                         "neurocytoma-subset")

output_file <- file.path(output_dir, "neurocytoma_subtyping_path_dx_strings.json")

if(!dir.exists(output_dir)){
  dir.create(output_dir)
}


# In this module, pathology_diagnosis is sufficient to subset all samples:
exact_path_dx<- "Neurocytoma"


# Create a list with the strings we'll use for inclusion.
terms_list <- list(exact_path_dx = exact_path_dx)


#Save this list as JSON.
writeLines(jsonlite::prettify(jsonlite::toJSON(terms_list)), output_file)
