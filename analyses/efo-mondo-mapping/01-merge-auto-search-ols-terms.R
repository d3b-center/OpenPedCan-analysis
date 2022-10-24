# Load required libraries

suppressPackageStartupMessages({
  library(optparse)
  library(dplyr)
  library(readr)
})

# Declare command line options
option_list <- list(
  optparse::make_option(
    c("--map_prefill"),
    type = "character",
    help = "Input prefill file with EFO and MONDO codes prior to curation"
  ),
  #optparse::make_option(
  #  c("--map_curr"),
  #  type = "character",
  #  help = "Current mapping file with OLS codes for all cancer_group"
  #),
  optparse::make_option(
    c("--efo_auto_prefill"),
    type = "character",
    help = "Auto generated EFO codes file"
  ),
  optparse::make_option(
    c("--mondo_auto_prefill"),
    type = "character",
    help = "Auto generated MONDO codes file"
  ),
  optparse::make_option(
    c("--ncit_auto_prefill"),
    type = "character",
    help = "Auto generated MONDO codes file"
  ),
  optparse::make_option(
    c("--out_dir"),
    type = "character",
    default = "results",
    help = "Directory for output file"
  ),
  optparse::make_option(
    c("--out_file"),
    type = "character",
    default = "efo-mondo-map-prefill-auto.tsv",
    help = "Output file name"
  )
)

# Read the arguments passed
opt_parser <- optparse::OptionParser(option_list = option_list)
opt <- optparse::parse_args(opt_parser)

out_dir <- opt$out_dir
out_file <- opt$out_file

#Extract the contents of `results/efo-mondo-map-prefill.tsv` and join with the new automated search results
map_prefill <- read_tsv(opt$map_prefill)
efo_auto_prefill <- read_tsv(file.path(out_dir,opt$efo_auto_prefill))
mondo_auto_prefill <- read_tsv(file.path(out_dir,opt$mondo_auto_prefill))
ncit_auto_prefill <- read_tsv(file.path(out_dir,opt$ncit_auto_prefill))
#map_curr <- read_tsv(file.path(results_dir,"efo-mondo-map.tsv"))

map_prefill_auto <- dplyr::inner_join(map_prefill,efo_auto_prefill,by="cancer_group") %>%
  dplyr::inner_join(.,mondo_auto_prefill,by="cancer_group") %>%
  dplyr::inner_join(.,ncit_auto_prefill,by="cancer_group") %>%
  rename(efo_code_prefill=efo_code.x, 
         mondo_code_prefill=mondo_code.x,
         efo_code_auto=efo_code.y,
         mondo_code_auto=mondo_code.y,
         ncit_code_auto=ncit_code) %>%
  select(cancer_group, efo_code_prefill,mondo_code_prefill,efo_code_auto,
         mondo_code_auto,ncit_code_auto,efo_OntoDesc,mondo_OntoDesc,ncit_OntoDesc) %>%
  mutate(efo_desc_match = case_when(tolower(cancer_group) == tolower(efo_OntoDesc) ~ "True",
                                    TRUE ~ as.character("False"))) %>%
  mutate(mondo_desc_match = case_when(tolower(cancer_group) == tolower(mondo_OntoDesc) ~ "True",
                                      TRUE ~ as.character("False"))) %>%
  mutate(ncit_desc_match = case_when(tolower(cancer_group) == tolower(ncit_OntoDesc) ~ "True",
                                     TRUE ~ as.character("False"))) %>%
  mutate(efo_code_match = case_when(efo_code_prefill == efo_code_auto ~ "True",
                                    TRUE ~ as.character("False"))) %>%
  mutate(mondo_code_match = case_when(mondo_code_prefill == mondo_code_auto ~ "True",
                                      TRUE ~ as.character("False"))) %>%
  mutate(ncit_code_match = "False")  #ncit_code_match is hard-coded "False" since it does not exist in prefill table



### Write merged file with all code comparisons to `results`

out_file <- file.path(out_dir, out_file)
readr::write_tsv(map_prefill_auto, out_file)


