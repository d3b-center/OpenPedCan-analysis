#Author: Sangeeta Shukla
#Purpose: This script creates a subset of the histologies.tsv. 
#         The subset can then be used as input to test the main script of this module.

# Load required libraries
suppressPackageStartupMessages({
  library(optparse)
  library(jsonlite)
  library(ggplot2)
  library(DESeq2)
})


# read params
option_list <- list(
  make_option(c("-c", "--hist_file"), type = "character",
              help = "Histology data file (.TSV)"),
  make_option(c("-n", "--counts_file"), type = "character",
              help = "Gene Counts file (.rds)"),
  make_option(c("-o", "--outdir"), type = "character",
              help = "Output Directory")
)


# parse the parameters
opt <- parse_args(OptionParser(option_list = option_list))



#Load histology file
#hist <- read.delim("../data/histologies.tsv", header=TRUE, sep = '\t')
hist <- read.delim(opt$hist_file, header=TRUE, sep = '\t')

#Load expression counts data
#countData <- readRDS("../data/gene-counts-rsem-expected_count-collapsed.rds")
countData <- readRDS(opt$counts_file)


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

#Create a filter to set threshold of more than 5 patients
patientCount_set <- subset(patientCount_set,patientCount_set$counts>5)

hist.filtered_final <- hist.filtered[which((hist.filtered$cancer_group %in% patientCount_set$cancerGroup &
                                              hist.filtered$cohort %in% patientCount_set$cohort )
                                           | !is.na(hist.filtered$gtex_group)),]

#Apply the filter to subset the original histologies.tsv
# Replace the desired cancer_group and cohort below
hist_subset <-
  hist.filtered_final[which(
    hist.filtered_final$cancer_group %in% c("CNS Embryonal tumor") &
      hist.filtered_final$cohort %in% c("PBTA") 
    | !is.na(hist.filtered_final$gtex_group)),]

# Save file
write.table(hist_subset,file=paste(opt$outdir,"/histologies_subset.tsv",sep=""),sep="\t",col.names = T, row.names = F,quote = F)



              
