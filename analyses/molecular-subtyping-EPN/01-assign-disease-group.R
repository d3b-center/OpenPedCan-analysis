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
  make_option(
    c("-p", "--path"), type = "character",
    default = NULL,
    help = "pathology-selecting json file"
  ),
  make_option(c("--outfile"), type = "character",
    help = "output tsv file; .gz for gzipped output.")
)
opt <- parse_args(OptionParser(option_list = option_list))
pbta_histologies <- read.delim(opt$histology)
outfile <- opt$outfile
path_dx_list <- jsonlite::fromJSON(opt$path)

# infra and supra categories
supra = c("frontal lobe", "parietal lobe", "occipital lobe", "temporal lobe")
infra = c("posterior fossa", "optic", "tectum")
spine = c("spinal", "spine")

# filter for ependymoma samples 
EP = pbta_histologies %>%
  filter(pathology_diagnosis %in% path_dx_list$exact_path_dx) %>%
  mutate(id = paste(sample_id, sample_type, tumor_descriptor, sep = "_"))


# update CNS region
cns_region <- EP %>%
  select(id, primary_site, CNS_region) %>%
  group_by(id, primary_site) %>%
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

# filter for RNA samples
EP_rnaseq_samples = EP %>%
  filter(experimental_strategy == "RNA-Seq" | (experimental_strategy == "Targeted Sequencing"
         & (!is.na(RNA_library)))) %>%
  dplyr::select(Kids_First_Biospecimen_ID, Kids_First_Participant_ID, sample_id, id, primary_site, CNS_region) %>%
  dplyr::rename("Kids_First_Biospecimen_ID_RNA" = "Kids_First_Biospecimen_ID")

# filter for RNA fusion panel
EP_rna_panel_samples = EP %>%
  filter(experimental_strategy == "Targeted Sequencing" & (!is.na(RNA_library))) %>%
  dplyr::select(Kids_First_Biospecimen_ID, Kids_First_Participant_ID, sample_id, id, primary_site, CNS_region) %>%
  dplyr::rename("Kids_First_Biospecimen_ID_RNA_panel" = "Kids_First_Biospecimen_ID")

# filter for DNA samples 
WGS_dnaseqsamples = EP %>%
  filter(experimental_strategy == "WGS" | experimental_strategy == "WXS" | experimental_strategy == "Targeted Sequencing",
         is.na(RNA_library)) %>%
  dplyr::select(Kids_First_Biospecimen_ID, Kids_First_Participant_ID, sample_id, id, primary_site, CNS_region) %>%
  dplyr::rename("Kids_First_Biospecimen_ID_DNA" = "Kids_First_Biospecimen_ID")

# filter for Methyl samples 
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
  dplyr::select(Kids_First_Biospecimen_ID, Kids_First_Participant_ID, sample_id, id, primary_site, CNS_region, molecular_subtype_methyl) %>%
  dplyr::rename("Kids_First_Biospecimen_ID_Methyl" = "Kids_First_Biospecimen_ID") %>% 
  dplyr::filter(!is.na(molecular_subtype_methyl)) %>% 
  dplyr::distinct() %>%
  # group these
  group_by(Kids_First_Participant_ID, sample_id, id, primary_site, CNS_region) %>%
  summarise(Kids_First_Biospecimen_ID_Methyl = toString(unique(Kids_First_Biospecimen_ID_Methyl)),
            molecular_subtype_methyl = toString(unique(molecular_subtype_methyl))) %>%
  ungroup()

# low confidence methylation classification subtypes
# replace same "patient_id-sample_id" in low confidence set that is  
# in high confidence set with high confidence classification subtype
methyl_not_subtyped <- EP %>%
  dplyr::filter(experimental_strategy == "Methylation", 
                cohort %in% c("PBTA", "DGD"),
                !Kids_First_Biospecimen_ID %in% unique(methyl_subtyped$Kids_First_Biospecimen_ID_Methyl)) %>%
  dplyr::left_join(methyl_subtyped %>% dplyr::select(Kids_First_Participant_ID, sample_id, id, molecular_subtype_methyl),
                   by = c("Kids_First_Participant_ID", "sample_id", "id")) %>% 
  dplyr::select(Kids_First_Biospecimen_ID, Kids_First_Participant_ID, sample_id, id, primary_site, CNS_region, molecular_subtype_methyl) %>%
  dplyr::rename("Kids_First_Biospecimen_ID_Methyl" = "Kids_First_Biospecimen_ID") %>% 
  dplyr::distinct() %>%
  # group these
  group_by(Kids_First_Participant_ID, sample_id, id, primary_site, CNS_region) %>%
  summarise(Kids_First_Biospecimen_ID_Methyl = toString(unique(Kids_First_Biospecimen_ID_Methyl)),
            molecular_subtype_methyl = toString(unique(molecular_subtype_methyl))) %>%
  ungroup() %>%
  mutate(molecular_subtype_methyl = case_when(molecular_subtype_methyl == "NA" ~ NA_character_,
                                              TRUE ~ molecular_subtype_methyl))

# merge methyl
methyl_samples = dplyr::bind_rows(methyl_subtyped, methyl_not_subtyped)

# merge rnaseq, wgs, methyl, rna panel
EP_rnaseq_WGS_methyl = EP_rnaseq_samples %>%
  dplyr::full_join(EP_rna_panel_samples, by = c("sample_id", "id", "Kids_First_Participant_ID","primary_site", "CNS_region")) %>% 
  dplyr::full_join(WGS_dnaseqsamples, by = c("sample_id", "id", "Kids_First_Participant_ID","primary_site", "CNS_region")) %>% 
  dplyr::full_join(methyl_samples, by = c("sample_id", "id", "Kids_First_Participant_ID","primary_site", "CNS_region")) 


# add disease group (supra/infra category) inferred from primary_site
EP_rnaseq_WGS_methyl <- EP_rnaseq_WGS_methyl %>%
  dplyr::mutate(disease_group_supra = ifelse(grepl(paste0(supra, collapse = "|"), tolower(primary_site)), "supratentorial", "undetermined"),
                disease_group_infra = ifelse(grepl(paste0(infra, collapse = "|"), tolower(primary_site)), "infratentorial", "undetermined"),
                disease_group_spine = ifelse(grepl(paste0(spine, collapse = "|"), tolower(primary_site)), "spinal", "undetermined"),
                disease_group = ifelse(disease_group_supra == "supratentorial" & disease_group_infra == "undetermined" & disease_group_spine == "undetermined", "supratentorial",
                                       ifelse(disease_group_supra == "undetermined" & disease_group_infra == "infratentorial" & disease_group_spine == "undetermined", "infratentorial",
                                              ifelse(disease_group_supra == "undetermined" & disease_group_infra == "undetermined" & disease_group_spine == "spinal", "spinal",
                                                     ifelse(disease_group_supra == "undetermined" & disease_group_infra == "undetermined" & disease_group_spine == "undetermined", "undetermined", "mixed"))))) %>%
  dplyr::arrange(Kids_First_Participant_ID, sample_id) %>%
  dplyr::select(Kids_First_Participant_ID, sample_id, id, Kids_First_Biospecimen_ID_DNA, Kids_First_Biospecimen_ID_RNA, Kids_First_Biospecimen_ID_RNA_panel,
                Kids_First_Biospecimen_ID_Methyl, CNS_region, primary_site, disease_group, molecular_subtype_methyl)


# write out
readr::write_tsv(EP_rnaseq_WGS_methyl, outfile)
