# Author: Komal S. Rathi
# R version of 01-make_notebook_RNAandDNA.py (Author: Teja Koganti)
# script to map DNA and RNA samples to a participant and assign disease group

# load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(optparse)
})

# Parse command line options
option_list <- list(
  make_option(c("--histology"), type = "character",
    help = "histology file tsv"),
  make_option(
    c("-p", "--path"), type = "character",
    default = NULL,
    help = "pathology-selecting json file"
  ),
  make_option(c("--outfile"), type = "character",
    help = "output tsv file; .gz for gzipped output.")
)
opt <- parse_args(OptionParser(option_list = option_list))
pbta_histologies <- read_tsv(opt$histology, guess_max = 100000)
outfile <- opt$outfile
path_dx_list <- jsonlite::fromJSON(opt$path)

# infra and supra categories
supra = c("frontal lobe", "parietal lobe", "occipital lobe", "temporal lobe")
infra = c("posterior fossa", "optic", "tectum")
spine = c("spinal", "spine")

# filter for ependymoma samples 
EP = pbta_histologies %>%
  filter(pathology_diagnosis %in% path_dx_list$exact_path_dx)

# update CNS region
cns_region <- EP %>%
  select(match_id, primary_site, CNS_region) %>%
  group_by(match_id, primary_site) %>%
  summarise(CNS_region = toString(unique(CNS_region))) %>%
  ungroup() %>%
  mutate(CNS_region = gsub("NA, |, NA", "", CNS_region),
         CNS_region = case_when(primary_site == "Other locations NOS" ~ "Other",
                                primary_site == "Ventricles" ~ "Ventricles",
                                primary_site %in% c("Frontal Lobe", "Parietal Lobe") ~ "Hemispheric",
                                primary_site == "Meninges/Dura;Ventricles" ~ "Mixed",
                                CNS_region == "NA" ~ NA_character_,
                                TRUE ~ CNS_region))

EP <- EP %>%
  select(-CNS_region) %>%
  left_join(cns_region)

# high confidence methylation classification subtypes
methyl_subtyped = EP %>%
  dplyr::filter(experimental_strategy == "Methylation",
                !is.na(pathology_diagnosis),
                cohort %in% c("PBTA", "DGD"),
                (grepl("EPN_", dkfz_v12_methylation_subclass) & dkfz_v12_methylation_subclass_score >= 0.8)) %>%
  dplyr::mutate(molecular_subtype_methyl = case_when(grepl("EPN_PFA", dkfz_v12_methylation_subclass) ~ "EPN, PF A",
                                                     grepl("EPN_PFB", dkfz_v12_methylation_subclass) ~ "EPN, PF B",
                                                     grepl("EPN_ST_ZFTA", dkfz_v12_methylation_subclass) ~ "EPN, ST ZFTA",
                                                     dkfz_v12_methylation_subclass == "EPN_MPE" ~ "EPN, MPE",
                                                     dkfz_v12_methylation_subclass == "EPN_PF_SE" ~ "EPN, PF SE",
                                                     dkfz_v12_methylation_subclass == "EPN_SPINE" ~ "EPN, SP",
                                                     dkfz_v12_methylation_subclass == "EPN_SPINE_MYCN" ~ "EPN, SP-MYCN",
                                                     dkfz_v12_methylation_subclass == "EPN_SPINE_SE_A" ~ "EPN, SP-SE",
                                                     dkfz_v12_methylation_subclass == "EPN_SPINE_SE_B" ~ "EPN, SP-SE",
                                                     dkfz_v12_methylation_subclass == "EPN_ST_SE" ~ "EPN, ST SE",
                                                     dkfz_v12_methylation_subclass == "EPN_YAP" ~ "EPN, ST YAP1")) %>%
  dplyr::select(match_id, molecular_subtype_methyl) %>%
  dplyr::filter(!is.na(molecular_subtype_methyl)) %>% 
  dplyr::distinct() #%>%

# not high-confidence subtypes
methyl_not_subtyped <- EP %>%
  dplyr::filter(experimental_strategy == "Methylation", 
                cohort %in% c("PBTA", "DGD"),
                (grepl("EPN_", dkfz_v12_methylation_subclass) & dkfz_v12_methylation_subclass_score < 0.8)) %>%
  dplyr::left_join(methyl_subtyped %>% 
                     dplyr::select(match_id, molecular_subtype_methyl),by = "match_id") %>% 
  dplyr::select(match_id, molecular_subtype_methyl) %>%
  dplyr::distinct() %>%
  mutate(molecular_subtype_methyl = case_when(molecular_subtype_methyl == "NA" ~ NA_character_,
                                              TRUE ~ molecular_subtype_methyl))

# merge methyl
methyl_samples = dplyr::bind_rows(methyl_subtyped, methyl_not_subtyped) %>%
  unique()

# add all BS ids by match_id
all_samples <- EP[,c("Kids_First_Participant_ID", "Kids_First_Biospecimen_ID", "sample_id", "match_id", "primary_site", "CNS_region")] %>%
  left_join(methyl_samples, by = "match_id") %>% 
  unique()

# add disease group (supra/infra category) inferred from primary_site
all_samples_dis_gp <- all_samples %>%
  dplyr::mutate(disease_group_supra = ifelse(grepl(paste0(supra, collapse = "|"), tolower(primary_site)), "supratentorial", "undetermined"),
                disease_group_infra = ifelse(grepl(paste0(infra, collapse = "|"), tolower(primary_site)), "infratentorial", "undetermined"),
                disease_group_spine = ifelse(grepl(paste0(spine, collapse = "|"), tolower(primary_site)), "spinal", "undetermined"),
                disease_group = ifelse(disease_group_supra == "supratentorial" & disease_group_infra == "undetermined" & disease_group_spine == "undetermined", "supratentorial",
                                       ifelse(disease_group_supra == "undetermined" & disease_group_infra == "infratentorial" & disease_group_spine == "undetermined", "infratentorial",
                                              ifelse(disease_group_supra == "undetermined" & disease_group_infra == "undetermined" & disease_group_spine == "spinal", "spinal",
                                                     ifelse(disease_group_supra == "undetermined" & disease_group_infra == "undetermined" & disease_group_spine == "undetermined", "undetermined", "mixed"))))) %>%
  dplyr::arrange(Kids_First_Participant_ID, sample_id) 
  
# write out
readr::write_tsv(all_samples_dis_gp, outfile)
