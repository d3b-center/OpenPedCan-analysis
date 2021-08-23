# Author: Sangeeta Shukla
# This script servers as a precursor to the DESeq analysis step, as it calculates the GTEx_index, Hist_Index values
# This script also creates Histology and Counts data subsets which satisfy given clinical criteria 



#Load histology file
hist <- read.delim("../../data/v7/histologies_original.tsv", header=TRUE, sep = '\t')
#hist <- read.delim(opt$hist_file, header=TRUE, sep = '\t')

#Load expression counts data
countData <- readRDS("../../data/v7/gene-counts-rsem-expected_count-collapsed.rds")
#countData <- readRDS(opt$counts_file)




# Subset Histology file for samples only found in the current the countData file (To ensure no discepancies cause errors later in the code)
hist.filtered <- unique(hist[which(hist$Kids_First_Biospecimen_ID %in%  colnames(countData)),])


# Create an array of unique cancer_group found in histologies.tsv
cancerGroup <- unique(hist.filtered$cancer_group)
cancerGroup <- cancerGroup[which(!is.na(cancerGroup))]

# Create an array of unique research cohorts found in histologies.tsv
resCohort <- unique(hist.filtered$cohort)
resCohort <- resCohort[which(!is.na(resCohort))]

# Combine the cancer_group and cohort as columns in a new array
cancerGroup_cohort_set <- expand.grid(cancerGroup=cancerGroup,cohort=resCohort)

# Create a new array which can take each combination of cancer_group+cohort 
# Add another column with counts of patients whose data is available for that combination
patientCount_set <- data.frame()

for (I in 1:length(cancerGroup_cohort_set$cancerGroup))
{
  patientCount_set <- rbind(patientCount_set, 
                            data.frame(cancerGroup=cancerGroup_cohort_set$cancerGroup[I], 
                                       cohort=cancerGroup_cohort_set$cohort[I], 
                                       counts=length(unique(hist.filtered$Kids_First_Biospecimen_ID[
                                         which(hist.filtered$cancer_group == cancerGroup_cohort_set$cancerGroup[I] 
                                               & hist.filtered$cohort == cancerGroup_cohort_set$cohort[I])
                                       ]
                                       )
                                       )
                            )
  )
}

#colnames(patientCount_set)

patientCount_set <- subset(patientCount_set,patientCount_set$counts>5)

hist.filtered_final <- hist.filtered[which((hist.filtered$cancer_group %in% patientCount_set$cancerGroup &
                                              hist.filtered$cohort %in% patientCount_set$cohort )
                                           | !is.na(hist.filtered$gtex_group)),]


#colnames(hist.filtered_final)

#length(hist.filtered_final$gtex_subgroup) --> 19848
#length(unique(hist.filtered_final$gtex_subgroup)) --> 54
#length(unique(hist.filtered_final$gtex_subgroup[which(!is.na(hist.filtered_final$gtex_subgroup))])) --> 53
#length(unique(hist.filtered_final$gtex_group)) -->32
#length(unique(hist.filtered_final$gtex_group[which(!is.na(hist.filtered_final$gtex_group))])) --> 31
#unique(hist.filtered_final$cancer_group) --> 29



#Subset countdata for data that are present in the hitstoly files (To ensure no discepancies cause errors later in the code)
countData_filtered <- countData[,which(colnames(countData) %in% hist.filtered_final$Kids_First_Biospecimen_ID)]


#Save all the unique cancer histologies in a variable. These cancer histologies represent the patient data in the countsdata
Cancer_Histology <- unique(hist.filtered_final$cancer_group)

#Save all the GTEx tissue subgroups in a variable. These cancer histologies represent the GTEx RNDA data available in the countsdata
Gtex_Tissue_subgroup <- sort(unique(hist.filtered_final$gtex_subgroup))


#Save all the cohorts represented in the countsdata into a variable. Remove all 'NA's from the list. 
#And paste cohort to cancer groep (eg GMKF_Neuroblastoma)
Cancer_Histology_COHORT <- unique(
  paste(hist.filtered_final$cohort[which(!is.na(hist.filtered_final$cancer_group))],
        hist.filtered_final$cancer_group[which(!is.na(hist.filtered_final$cancer_group))],
        sep="_")
)

#Save all the histologies represented in the countsdata into a variable. 
#Remove all 'NA's from the list. 
#This will be the basis of all the data from each histology combined regardless of cohort (eg all-cohorts_Neuroblastoma)
Cancer_Histology <- paste("all-cohorts",Cancer_Histology[which(!is.na(Cancer_Histology))],sep="_")


#Save all the GTEx subgroups represented in the countsdata into a variable. Remove all 'NA's 
Gtex_Tissue_subgroup <- Gtex_Tissue_subgroup[!is.na(Gtex_Tissue_subgroup)]

#Create an empty df to populate with rbind of all normal Kids_First_Biospecimen_ID and gtex_subgroup
#Create DF that list all Kids_First_Biospecimen_IDs by GTEX subgroup
sample_type_df_normal <- data.frame()
for(I in 1:length(Gtex_Tissue_subgroup))
{
  sample_type_df_normal <- rbind(sample_type_df_normal,
                                 data.frame(Case_ID = hist.filtered_final$Kids_First_Biospecimen_ID[which(hist.filtered_final$gtex_subgroup == Gtex_Tissue_subgroup[I])]
                                            ,Type = Gtex_Tissue_subgroup[I]), stringsAsFactors = FALSE)
}

#Create an empty df to populate with rbind of all tumor Kids_First_Biospecimen_ID and cancer_group
#Create DF that list all Kids_First_Biospecimen_IDs by cancer group subgroup
sample_type_df_tumor <- data.frame()
for(I in 1:length(Cancer_Histology))
{
  sample_type_df_tumor <- rbind(sample_type_df_tumor,data.frame(Case_ID = hist.filtered_final$Kids_First_Biospecimen_ID[which(hist.filtered_final$cancer_group == gsub("all-cohorts_","",Cancer_Histology[I]))]
                                                                ,Type=Cancer_Histology[I], stringsAsFactors = FALSE))
}

#Create an empty df to populate with rbind of all tumor Kids_First_Biospecimen_ID and cancer_group by cohort
#Create DF that list all Kids_First_Biospecimen_IDs by Cohort - Cancer groups
sample_type_df_tumor_cohort <- data.frame()
for(I in 1:length(Cancer_Histology_COHORT))
{
  Cancer_Histology_COHORT_cohort <- strsplit(Cancer_Histology_COHORT[I],split="_")[[1]][1]
  Cancer_Histology_COHORT_cancer_group <- strsplit(Cancer_Histology_COHORT[I],split="_")[[1]][2]
  sample_type_df_tumor_cohort <- rbind(sample_type_df_tumor_cohort,
                                       data.frame(Case_ID = hist.filtered$Kids_First_Biospecimen_ID[which(hist.filtered$cancer_group == Cancer_Histology_COHORT_cancer_group 
                                                                                                          & hist.filtered$cohort == Cancer_Histology_COHORT_cohort)]
                                                  ,Type=Cancer_Histology_COHORT[I], stringsAsFactors = FALSE))
}

#Combine the rows from the normal and tumor sample df
sample_type_df <- rbind(sample_type_df_tumor,sample_type_df_tumor_cohort,sample_type_df_normal)


#Filter one more to ensure the rownames in the countsdata file match the sample dataframe for DEG just created
countData_filtered_DEG <- countData_filtered[,which(colnames(countData_filtered) %in% sample_type_df$Case_ID)]

#Filter one more to ensure the rownames in the countsdata file match the sample dataframe for DEG just created
sample_type_df_filtered <- unique(sample_type_df[which(sample_type_df$Case_ID %in% colnames(countData_filtered_DEG)),])

#Define All cancer groups (Combined and cohort-specific) in the histology list
histology_filtered <- unique(sample_type_df_filtered$Type[-grep("^GTEX",sample_type_df_filtered$Case_ID)])

#Define All GTEx groups as normal in the GTEX_filtered list
GTEX_filtered <- unique(sample_type_df_filtered$Type[grep("^GTEX",sample_type_df_filtered$Case_ID)])


fileConn_GTEx<-file("GTEx_Index_limit.txt",open = "w")
write.table(length(GTEX_filtered), file = fileConn_GTEx, append = FALSE, row.names = FALSE, col.names = FALSE)
close(fileConn_GTEx) 

fileConn_Hist<-file("Hist_Index_limit.txt",open = "w")
write.table(length(hist.filtered), file = fileConn_Hist, append = FALSE, row.names = FALSE, col.names = FALSE)
close(fileConn_Hist) 


write.table(hist.filtered_final, file="histology_subset.tsv", sep="\t", col.names = T, row.names = F,quote = F)
saveRDS(countData_filtered,file="countData_subset.rds")



#Test --> Load histology_subset file
hist_test <- read.delim("histology_subset.tsv", header=TRUE, sep = '\t')

#Load expression counts data
countData_test <- readRDS("countData_subset.rds")


