# Author: Sangeeta Shukla
# Date: June 2021
# Function: 
# 1. summarize Differential expression from RNASeq data
# 2. tabulate corresponding P-value

# Example run: DESeq
# Rscript analyses/DESeq/run-DESeq-analysis.R 


suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(BiocGenerics))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))

suppressPackageStartupMessages({
    library(ggplot2)
    library(DESeq2)
})


#Load histology file
hist <- read.delim("/Users/shuklas1/Git_Code/OpenPedCan-analysis/OpenPedCan-analysis/data/v5/histologies.tsv", header=TRUE, sep = '\t')

#Load expression counts data
countData <- readRDS("/Users/shuklas1/Git_Code/OpenPedCan-analysis/OpenPedCan-analysis/data/v5/gene-counts-rsem-expected_count-collapsed.rds")


#Verify if the files were loaded successfully with appropriate data
countData[1:5,1:5]
hist[1:5,]

colnames(hist)
colnames(countData)

#Verify if the GTEX and BS data is found in both counts and hist files
colnames(countData)[grep("BS",colnames(countData))]
hist$Kids_First_Biospecimen_ID[grep("BS",hist$Kids_First_Biospecimen_ID)]


#Test intersection between hist and counts for "BS" and "GTEX" each
intersect(
  hist$Kids_First_Biospecimen_ID[grep("BS",hist$Kids_First_Biospecimen_ID)],
  colnames(countData)[grep("BS",colnames(countData))]
)



#summary(countData)
nrow(countData)
ncol(countData)

#summary(hist)
nrow(hist)
ncol(hist)



hist.filtered = unique(hist[which(hist$Kids_First_Biospecimen_ID %in%  colnames(countData)),])
countData_filtered = countData[,which(colnames(countData) %in% hist$Kids_First_Biospecimen_ID)]


#summary(countData)
nrow(countData_filtered)
ncol(countData_filtered)

#summary(hist)
nrow(hist.filtered)
ncol(hist.filtered)



Cancer_Histology <- unique(hist.filtered$cancer_group)
Gtex_Tissue_subgroup = sort(unique(hist.filtered$gtex_subgroup))


Cancer_Histology <- Cancer_Histology[which(!is.na(Cancer_Histology))]



#Gtex_Tissue_subgroup
#sample_type_df_tumor = data.frame(Case_ID = hist$Kids_First_Biospecimen_ID[which(hist$short_histology == Cancer_Histology[1])],Type=hist$short_histology[which(hist$short_histology == Cancer_Histology[1])])
#sample_type_df_normal = data.frame(Case_ID = hist$Kids_First_Biospecimen_ID[which(hist$gtex_group == Gtex_Tissue[1])],Type=paste(hist$gtex_group[which(hist$gtex_group == Gtex_Tissue[1])],"-",hist$gtex_subgroup[which(hist$gtex_subgroup == Gtex_Tissue[1])] )  )
#sample_type_df_normal = data.frame(Case_ID = hist$Kids_First_Biospecimen_ID[which(hist$gtex_subgroup == Gtex_Tissue_subgroup[1])],Type=hist$gtex_group[which(hist$gtex_subgroup == Gtex_Tissue_subgroup[1])])

Gtex_Tissue_subgroup = Gtex_Tissue_subgroup[!is.na(Gtex_Tissue_subgroup)]


#Create an empty df to populate with rbind of all normal Kids_First_Biospecimen_ID and gtex_subgroup
sample_type_df_normal = data.frame()
for(I in 1:length(Gtex_Tissue_subgroup))
{
  sample_type_df_normal = rbind(sample_type_df_normal,data.frame(Case_ID = hist.filtered$Kids_First_Biospecimen_ID[which(hist.filtered$gtex_subgroup == Gtex_Tissue_subgroup[I])],Type = Gtex_Tissue_subgroup[I]))
}


#Create an empty df to populate with rbind of all tumor Kids_First_Biospecimen_ID and cancer_group
sample_type_df_tumor = data.frame()
for(I in 1:length(Cancer_Histology))
{
  sample_type_df_tumor = rbind(sample_type_df_tumor,data.frame(Case_ID = hist.filtered$Kids_First_Biospecimen_ID[which(hist.filtered$cancer_group == Cancer_Histology[I])],Type=Cancer_Histology[I]))
}


#Combine the rows from the normal and tumor sample df
sample_type_df = rbind(sample_type_df_tumor,sample_type_df_normal)

#Verify if the new data frame is populated correctly
head(sample_type_df)
tail(sample_type_df)

nrow(sample_type_df)
ncol(countData_filtered)


countData_filtered_DEG = countData_filtered[,which(colnames(countData_filtered) %in% sample_type_df$Case_ID)]
sample_type_df_filtered = unique(sample_type_df[which(sample_type_df$Case_ID %in% colnames(countData_filtered_DEG)),])
nrow(sample_type_df_filtered)
ncol(countData_filtered_DEG)

histology_filtered = unique(sample_type_df_filtered$Type[-grep("GTEX",sample_type_df_filtered$Case_ID)])
GTEX_filtered = unique(sample_type_df_filtered$Type[grep("GTEX",sample_type_df_filtered$Case_ID)])

ALL_comparisons <- list()
for(I in 1:length(histology_filtered)){
  for(J in 1:length(GTEX_filtered)){
    
      
      
      countData_filtered_DEG.hist = data.matrix(countData_filtered_DEG[,which(colnames(countData_filtered_DEG) %in% sample_type_df_filtered$Case_ID[which(sample_type_df_filtered$Type %in% c(histology_filtered[I],GTEX_filtered[J]))])])
                                                                           
      sample_type_df_filtered.hist = sample_type_df_filtered[which(sample_type_df_filtered$Type %in% c(histology_filtered[I],GTEX_filtered[J])),]
      
      all(is.numeric(countData_filtered_DEG.hist))
      round(countData_filtered_DEG.hist[1:5,1:4])
      
      sub.deseqdataset <- DESeqDataSetFromMatrix(countData=round(countData_filtered_DEG.hist),
                                                 colData=sample_type_df_filtered.hist,
                                                 design= ~ Type)
      
      #sub.deseqdataset <- DESeqDataSetFromMatrix(countData=countData_filtered_DEG,
      #                                           colData=sample_type_df_filtered,
      #                                           design= ~Type)
      
      #sub.deseqdataset[1:5,1:5]
      sub.deseqdataset <- sub.deseqdataset[ rowSums(counts(sub.deseqdataset)) > 0, ]
      
      
      sub.deseqdataset$Type <- factor(sub.deseqdataset$Type, levels=c(GTEX_filtered[J], histology_filtered[I]))
      #dataset$Status <- factor(dataset$Status, levels=c("Nonamplified", "Amplified"))
      
      dds <- DESeq(sub.deseqdataset)
      res <- results(dds)
      resOrdered <- res[order(res$padj),]
      
      Result = data.matrix(data_frame(log2FC = as.numeric(resOrdered$log2FoldChange), log2p= log2(as.numeric(resOrdered$padj+0.00001))))
      rownames(Result) <- as.character(rownames(resOrdered))
    
      ALL_comparisons <- c(ALL_comparisons,list(Result))
      
      rm(sub.deseqdataset)
  }#for(J in 1:length(GTEX_filtered)){
}#for(I in 1:length(histology_filtered)){


#head(res, tidy=TRUE)

#summary(resOrdered)

# Put the resulting list in a file for later use







