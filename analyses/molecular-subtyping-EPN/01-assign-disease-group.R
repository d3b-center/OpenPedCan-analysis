# Author: Komal S. Rathi
# R version of 01-make_notebook_RNAandDNA.py (Author: Teja Koganti)
# script to map DNA and RNA samples to a participant and assign disease group

# load libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(optparse)
})

# Parse command line options
option_list <- list(
  make_option(c("--histology"), type = "character",
    help = "histology file tsv"),
  make_option(c("--outfile"), type = "character",
    help = "output tsv file; .gz for gzipped output.")
)
opt <- parse_args(OptionParser(option_list = option_list))
pbta_histologies <- read.delim(opt$histology)
outfile <- opt$outfile

# infra and supra categories
supra = c("frontal lobe", "parietal lobe", "occipital lobe", "temporal lobe")
infra = c("posterior fossa", "optic", "tectum")
spine = c("spinal", "spine")

# filter for ependymoma samples 
EP = pbta_histologies %>%
  filter(pathology_diagnosis =="Ependymoma")

# filter for RNA samples
EP_rnaseq_samples = EP %>%
  filter(experimental_strategy == "RNA-Seq") %>%
  dplyr::select(Kids_First_Biospecimen_ID, Kids_First_Participant_ID, sample_id, primary_site, CNS_region) %>%
  dplyr::rename("Kids_First_Biospecimen_ID_RNA" = "Kids_First_Biospecimen_ID")

# filter for DNA samples 
WGS_dnaseqsamples = EP %>%
  filter(experimental_strategy == "WGS") %>%
  dplyr::select(Kids_First_Biospecimen_ID, Kids_First_Participant_ID, sample_id, primary_site, CNS_region) %>%
  dplyr::rename("Kids_First_Biospecimen_ID_DNA" = "Kids_First_Biospecimen_ID")

# sample_id is common between both  dataframes and also unique between RNA and DNA. 
# Some DNA BSID's are missing for the corresponding RNA samples
EP_rnaseq_WGS = EP_rnaseq_samples %>%
  full_join(WGS_dnaseqsamples, by = c("sample_id", "Kids_First_Participant_ID","primary_site", "CNS_region"))

# add disease group (supra/infra category) inferred from primary_site
EP_rnaseq_WGS <- EP_rnaseq_WGS %>%
  mutate(disease_group_supra = ifelse(grepl(paste0(supra, collapse = "|"), tolower(primary_site)), "supratentorial", "undetermined"),
         disease_group_infra = ifelse(grepl(paste0(infra, collapse = "|"), tolower(primary_site)), "infratentorial", "undetermined"),
         disease_group_spine = ifelse(grepl(paste0(spine, collapse = "|"), tolower(primary_site)), "spinal", "undetermined"),
         disease_group = ifelse(disease_group_supra == "supratentorial" & disease_group_infra == "undetermined" & disease_group_spine == "undetermined", "supratentorial",
                                ifelse(disease_group_supra == "undetermined" & disease_group_infra == "infratentorial" & disease_group_spine == "undetermined", "infratentorial",
                                       ifelse(disease_group_supra == "undetermined" & disease_group_infra == "undetermined" & disease_group_spine == "spinal", "spinal",
                                              ifelse(disease_group_supra == "undetermined" & disease_group_infra == "undetermined" & disease_group_spine == "undetermined", "undetermined", "mixed"))))) %>%
  arrange(Kids_First_Participant_ID, sample_id) %>%
  dplyr::select(Kids_First_Participant_ID, sample_id, 
                Kids_First_Biospecimen_ID_DNA, Kids_First_Biospecimen_ID_RNA,
                CNS_region, primary_site, disease_group)


# write out
readr::write_tsv(EP_rnaseq_WGS, outfile)
