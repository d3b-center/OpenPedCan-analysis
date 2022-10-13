setwd("~/OpenPedCan-analysis/analyses/molecular-subtyping-NBL")
source('~/OpenPedCan-analysis/analyses/molecular-subtyping-NBL/independent_rna_samples_NBL.R')
library(dplyr)
library(data.table)

# Load the files from the ticket
consensus_df<-as.data.frame(fread("/home/rstudio/OpenPedCan-analysis/data/consensus_wgs_plus_cnvkit_wxs.tsv.gz"))
hist_df<- as.data.frame(fread("/home/rstudio/OpenPedCan-analysis/data/histologies.tsv"))
cnv_cnvkit_df<-as.data.frame(fread("/home/rstudio/OpenPedCan-analysis/data/cnv-cnvkit.seg.gz"))
cnv_controlfreec_df<-as.data.frame(fread("/home/rstudio/OpenPedCan-analysis/data/cnv-controlfreec.tsv.gz"))
gene_expression_df<-as.data.frame(readRDS("/home/rstudio/OpenPedCan-analysis/data/gene-expression-rsem-tpm-collapsed.rds"))


######## PART 1 ########################################################
# For each NBL sample, gather MYCN amplification status 

## Step 1: Filter the neuroblastoma, ganglioneuroblastoma, and ganglioneuroma samples from hist file first
hist_filtered_df <- hist_df %>% filter(cancer_group=="Neuroblastoma"|
                                       cancer_group=="Ganglioneuroblastoma"|
                                        cancer_group=="Ganglioneuroma")

hist_filtered_df2 <- hist_df %>% filter(pathology_diagnosis=="Neuroblastoma"|
                                         pathology_diagnosis=="Ganglioneuroblastoma"|
                                         pathology_diagnosis=="Ganglioneuroblastoma,nodular"|
                                         pathology_diagnosis=="Ganglioneuroblastoma, intermixed"|
                                         pathology_diagnosis=="Ganglioneuroma, maturing subtype OR Ganglioneuroblastoma, well differentiated")
## Step 2: Filter the MCYN records from consensus_wgs_plus_cnvkit_wxs.tsv.gz
consensus_filtered_df <- consensus_df %>% filter(gene_symbol=="MYCN")

## Step 3 Join the two data frames to get MYCN details with respect to the diagnosis. Joining with the intersection of the data frames.
MYCN_df <- inner_join(hist_filtered_df,consensus_filtered_df,by= c("Kids_First_Biospecimen_ID" = "biospecimen_id"))

######## PART 2 ########################################################

# Create alterations/output table for matched DNA/RNA biospecimens. Match ID can be adapted from the independent-samples module
# DNA and RNA information are present in the Kids_First_Biospecimen_ID of column of Myc_df 

## Step 1: Create the DNA and RNA subset of MYC_df
# dna_myc_df <- is.na(RNA_library) and  experimental_strategy %in% c("WGS", "WXS", "Targeted Sequencing")
# dna_df <- Myc_df %>% filter(is.na(RNA_library),experimental_strategy %in% c("WGS", "WXS", "Targeted Sequencing") )
# rna_df <- Myc_df %>% filter(experimental_strategy == "RNA-Seq") 
