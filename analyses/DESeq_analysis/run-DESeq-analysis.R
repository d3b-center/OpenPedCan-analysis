# Author: Sangeeta Shukla and Alvin Farrel
# Date: June 2021
# Function: 
# 1. summarize Differential expression from RNASeq data
# 2. tabulate corresponding P-value

# Example run: DESeq
# Rscript analyses/DESeq/run-DESeq-analysis.R 1 1
# This was compares 1 cancer group (Combined or Cohort specific) with one GTEx tissue type. The input arguments are the indices of the comparison of the cancer groups and gtex sub tissues to be compared. In v6, there are 107 cancer groups vs 54 GTEx tissues

# Read arguments from terminal
args <- commandArgs(trailingOnly = TRUE)

# Load required libraries
suppressPackageStartupMessages({
  library(ggplot2)
  #library(DESeq2)
})


HIST_index <- args[1]   #assign first argument to Histology index
GTEX_index <- args[2]   #assign second argument to GTEx index

    



#Load histology file
hist <- read.delim("histologies.tsv", header=TRUE, sep = '\t')

#Load expression counts data
countData <- readRDS("gene-counts-rsem-expected_count-collapsed.rds")

#Load expression TPM data
TPMData <- readRDS("gene-expression-rsem-tpm-collapsed.rds")

#Load EFO-MONDO map file
EFO_MONDO <- read.delim("efo-mondo-map.tsv", header =T)

#Load gene symbol-gene ID RMTL file
ENSG_Hugo <- read.delim("ensg-hugo-rmtl-v1-mapping.tsv", header =T)

# Subset Histology file for samples only found in the current the countData file (To ensure no discepancies cause errors later in the code)
hist.filtered = unique(hist[which(hist$Kids_First_Biospecimen_ID %in%  colnames(countData)),])

#Subset countadata for data that are present in the hitstoly files (To ensure no discepancies cause errors later in the code)
countData_filtered = countData[,which(colnames(countData) %in% hist$Kids_First_Biospecimen_ID)]

#Subset countadata for data that are present in the hitstoly files (To ensure no discepancies cause errors later in the code)
TPMData_filtered = TPMData[,which(colnames(TPMData) %in% hist$Kids_First_Biospecimen_ID)]

#Save all the unique cancer histologies in a variable. These cancer histologies represent the patient data in the countsdata
Cancer_Histology <- unique(hist.filtered$cancer_group)

#Save all the GTEx tissue subgroups in a variable. These cancer histologies represent the GTEx RNDA data available in the countsdata
Gtex_Tissue_subgroup = sort(unique(hist.filtered$gtex_subgroup))

#Save all the cohorts represented in the countsdata into a variable. Renove all 'NA's from the list. and paste cohort to cancer groep (eg GMKF_Neuroblastoma)
Cancer_Histology_COHORT <- unique(paste(hist.filtered$cohort[which(!is.na(hist.filtered$cancer_group))],hist.filtered$cancer_group[which(!is.na(hist.filtered$cancer_group))],sep="_"))

#Save all the histologies represented in the countsdata into a variable. Renove all 'NA's from the list. This will be the basis of all the data from each histology combined regardless of cohort (eg Combined_Neuroblastoma)
Cancer_Histology <- paste("Combined",Cancer_Histology[which(!is.na(Cancer_Histology))],sep="_")


#Save all the GTEx subgroups represented in the countsdata into a variable. Remove all 'NA's 
Gtex_Tissue_subgroup = Gtex_Tissue_subgroup[!is.na(Gtex_Tissue_subgroup)]

#Create an empty df to populate with rbind of all normal Kids_First_Biospecimen_ID and gtex_subgroup
#Create DF that list all Kids_First_Biospecimen_IDs by GTEX subgroup
sample_type_df_normal = data.frame()
for(I in 1:length(Gtex_Tissue_subgroup))
{
  sample_type_df_normal = rbind(sample_type_df_normal,data.frame(Case_ID = hist.filtered$Kids_First_Biospecimen_ID[which(hist.filtered$gtex_subgroup == Gtex_Tissue_subgroup[I])],Type = Gtex_Tissue_subgroup[I]))
}

#Create an empty df to populate with rbind of all tumor Kids_First_Biospecimen_ID and cancer_group
#Create DF that list all Kids_First_Biospecimen_IDs by cancer group subgroup
sample_type_df_tumor = data.frame()
for(I in 1:length(Cancer_Histology))
{
  sample_type_df_tumor = rbind(sample_type_df_tumor,data.frame(Case_ID = hist.filtered$Kids_First_Biospecimen_ID[which(hist.filtered$cancer_group == gsub("Combined_","",Cancer_Histology[I]))],Type=Cancer_Histology[I]))
}

#Create an empty df to populate with rbind of all tumor Kids_First_Biospecimen_ID and cancer_group by cohort
#Create DF that list all Kids_First_Biospecimen_IDs by Cohort - Cancer groups
sample_type_df_tumor_cohort = data.frame()
for(I in 1:length(Cancer_Histology_COHORT))
{
  Cancer_Histology_COHORT_cohort =  strsplit(Cancer_Histology_COHORT[I],split="_")[[1]][1]
  Cancer_Histology_COHORT_cancer_group =  strsplit(Cancer_Histology_COHORT[I],split="_")[[1]][2]
  sample_type_df_tumor_cohort = rbind(sample_type_df_tumor_cohort,data.frame(Case_ID = hist.filtered$Kids_First_Biospecimen_ID[which(hist.filtered$cancer_group == Cancer_Histology_COHORT_cancer_group & hist.filtered$cohort == Cancer_Histology_COHORT_cohort)],Type=Cancer_Histology_COHORT[I]))
}

#Combine the rows from the normal and tumor sample df
sample_type_df = rbind(sample_type_df_tumor,sample_type_df_tumor_cohort,sample_type_df_normal)

#Filter one more to ensure the rownames in the countsdata file match the sample dataframe for DEG just created
countData_filtered_DEG = countData_filtered[,which(colnames(countData_filtered) %in% sample_type_df$Case_ID)]

#Filter one more to ensure the rownames in the countsdata file match the sample dataframe for DEG just created
sample_type_df_filtered = unique(sample_type_df[which(sample_type_df$Case_ID %in% colnames(countData_filtered_DEG)),])

#Define All cancer groups (Combined and cohort-specific) in the histology list
histology_filtered = unique(sample_type_df_filtered$Type[-grep("GTEX",sample_type_df_filtered$Case_ID)])

#Define All GTEx groups as normal in the GTEX_filtered list
GTEX_filtered = unique(sample_type_df_filtered$Type[grep("GTEX",sample_type_df_filtered$Case_ID)])

#Assign cmparison
 I = as.numeric(HIST_index)   #assign first argument to Histology index
 J = as.numeric(GTEX_index)   #assign second argument to GTEx index


    
#Subset countData_filtered_DEG dataframe for only the histology group and GTEx group being compared
    countData_filtered_DEG.hist = data.matrix(countData_filtered_DEG[,which(colnames(countData_filtered_DEG) %in% sample_type_df_filtered$Case_ID[which(sample_type_df_filtered$Type %in% c(histology_filtered[I],GTEX_filtered[J]))])])
    
#Subset sample type dataframe for only the histology group and GTEx group being compared
    sample_type_df_filtered.hist = sample_type_df_filtered[which(sample_type_df_filtered$Type %in% c(histology_filtered[I],GTEX_filtered[J])),]
    
#Run DESeq2  
    sub.deseqdataset <- DESeqDataSetFromMatrix(countData=round(countData_filtered_DEG.hist),
                                               colData=sample_type_df_filtered.hist,
                                               design= ~ Type)
    
    
    sub.deseqdataset$Type <- factor(sub.deseqdataset$Type, levels=c(GTEX_filtered[J], histology_filtered[I]))
    
    dds <- DESeq(sub.deseqdataset)
    res <- results(dds)
    resOrdered <- res[order(rownames(res)),]

    Result = resOrdered


#Save subset of table with samples representing the histology in the DEG comparison to a variable.
HIST_sample_type_df_filtered = sample_type_df_filtered[which(sample_type_df_filtered$Type %in% c(histology_filtered[I])),]
 
#Define study ID as all cohorts represented by the pateints involved in DEG comparison
STUDY_ID = paste(unique(hist$cohort[which(hist$Kids_First_Biospecimen_ID %in% HIST_sample_type_df_filtered$Case_ID)]),collapse=";",sep=";")

#Record number of samples represnt the GTEX tissue used in the comparison
GTEX_Hits = length(sample_type_df_filtered[which(sample_type_df_filtered$Type %in% c(GTEX_filtered[J])),1])

#Determine the mean TPM of the tissue. If there are multiple samples use the mean TPM
if(GTEX_Hits > 1) GTEX_MEAN_TPMs = round(apply(TPMData_filtered[match(rownames(Result),rownames(TPMData_filtered)),which(colnames(TPMData_filtered) %in%  sample_type_df_filtered[which(sample_type_df_filtered$Type %in% c(GTEX_filtered[J])),1])]  ,MARGIN=1, mean ),2)

#Determine the mean TPM of the tissue. If there is one sample just use the single TPM value of the sample
if(GTEX_Hits <= 1) GTEX_MEAN_TPMs = TPMData_filtered[match(rownames(Result),rownames(TPMData_filtered)),which(colnames(TPMData_filtered) %in%  sample_type_df_filtered[which(sample_type_df_filtered$Type %in% c(GTEX_filtered[J])),1])]

#Record number of samples represnt the cancer patient data used in the comparison
Cancer.Hist_Hits = length(sample_type_df_filtered[which(sample_type_df_filtered$Type %in% c(histology_filtered[I])),1])

#Determine the mean TPM of the tissue. If there are multiple samples use the mean TPM
if(Cancer.Hist_Hits > 1) Histology_MEAN_TPMs = round(apply(TPMData_filtered[match(rownames(Result),rownames(TPMData_filtered)),which(colnames(TPMData_filtered) %in%  sample_type_df_filtered[which(sample_type_df_filtered$Type %in% c(histology_filtered[I])),1])]  ,MARGIN=1, mean ),2)

#Determine the mean TPM of the tissue. If there is one sample just use the single TPM value of the sample
if(Cancer.Hist_Hits <= 1) Histology_MEAN_TPMs = TPMData_filtered[match(rownames(Result),rownames(TPMData_filtered)),which(colnames(TPMData_filtered) %in%  sample_type_df_filtered[which(sample_type_df_filtered$Type %in% c(histology_filtered[I])),1])]

#Round the mean TPMs to the 2 decimal places
Histology_MEAN_TPMs = round(Histology_MEAN_TPMs,2)
GTEX_MEAN_TPMs = round(GTEX_MEAN_TPMs,2)


#Create Final Dataframe with all the info calculated and extracted from histology file Including EFO/MONDO codes where available and RMTL status
Final_Data_Table = data.frame(
  datasourceId = paste(strsplit(histology_filtered[I],split="_")[[1]][1],"vs_GTex",sep="_"),
  datatypeId = "rna_expression",
  cohort = paste(unique(hist$cohort[which(hist$Kids_First_Biospecimen_ID %in% HIST_sample_type_df_filtered$Case_ID)]),collapse=";",sep=";"),
  gene_symbol = rownames(Result),
  gene_id = ENSG_Hugo$ensg_id[match(rownames(Result),ENSG_Hugo$gene_symbol)],
  RMTL = ENSG_Hugo$rmtl[match(rownames(Result),ENSG_Hugo$gene_symbol)],
  EFO = ifelse(length(which(EFO_MONDO$cancer_group == unique(hist$cancer_group[which(hist$Kids_First_Biospecimen_ID %in% HIST_sample_type_df_filtered$Case_ID)]))) >= 1, EFO_MONDO$efo_code[which(EFO_MONDO$cancer_group == unique(hist$cancer_group[which(hist$Kids_First_Biospecimen_ID %in% HIST_sample_type_df_filtered$Case_ID)]))], "" ),
  MONDO = ifelse(length(which(EFO_MONDO$cancer_group == unique(hist$cancer_group[which(hist$Kids_First_Biospecimen_ID %in% HIST_sample_type_df_filtered$Case_ID)]))) >= 1,EFO_MONDO$mondo_code[which(EFO_MONDO$cancer_group == unique(hist$cancer_group[which(hist$Kids_First_Biospecimen_ID %in% HIST_sample_type_df_filtered$Case_ID)]))],""),
  comparisonId = gsub(" |/|;|:|\\(|)","_",paste(histology_filtered[I],GTEX_filtered[J],sep="_v_")),
  cancer_group = paste(unlist(strsplit(histology_filtered[I],split="_"))[-1],collapse=" "),
  cancer_group_Count = Cancer.Hist_Hits,
  GTEx = GTEX_filtered[J],
  GTEx_Count = GTEX_Hits,
  cancer_group_MeanTpm = Histology_MEAN_TPMs,
  GTEx_MeanTpm = GTEX_MEAN_TPMs,
  Result
)#Final_Data_Table = data.frame(


#Save files
system("mkdir Results/")

#Define file name as Histoloy_v_Gtex.tsv and replacing all 'special symbols' with '_' for the filename
FILENAME <- gsub(" |/|;|:|\\(|)","_",paste(histology_filtered[I],GTEX_filtered[J],sep="_v_"))
write.table(Final_Data_Table,file=paste("Results_5_forv6/",FILENAME,".tsv",sep=""),sep="\t",col.names = T, row.names = F,quote = F)




