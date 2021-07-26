# K. S. Gaonkar 2019
# Annotates standardizes fusion calls from callers [STARfusion| Arriba] or QC filtered fusion
# calls with zscored expression value from either GTEx/cohort . The input should have the following standardized
# columns to run through this GTEx/cohort normalization function
# "Sample"  Unique SampleIDs used in your RNAseq dataset
# "FusionName" GeneA--GeneB ,or if fusion is intergenic then Gene1A/Gene2A--GeneB
#
# Optional
# "LeftBreakpoint" Genomic location of breakpoint on the left
# "RightBreakpoint" Genomic location of breakpoint on the right
# "Fusion_Type" Type of fusion prediction from caller "inframe","frameshift","other"
# "Caller" Name of caller used for fusion prediction
# "JunctionReadCount" synonymous with split reads, provide evidence for the specific breakpoint
# "SpanningFragCount" fragment alignment where either mate does not cross the junction
# "Confidence" Estimated confidence of call from caller, if not available value is "NA"
# "annots" Annotation from FusionAnnotator
#
# Command line arguments
# fusionfile	: Merged fusion calls from [STARfusion| Arriba] or QC filtered fusion
# zscoreFilter	: Zscore value to use as threshold for annotation of differential expression
# gtexMatrix : Rds will be saved as "normData" with expression data (FPKM) for samples (colnames) and
#                               GeneSymbol( rownames) to be used to normalize samples
# expressionMatrix : expression matrix (FPKM for samples that need to be zscore normalized)
# saveZscoredMatrix : path to save zscored matrix from GTEx normalization
# outputFile	: Output file is a standardized fusion call set with standard
# column headers with additional columns below from expression annotation
# zscore_Gene1A : zscore from GTEx/cohort normalization for Gene1A
# zscore_Gene1B : zscore from GTEx/cohort normalization for Gene1B
# zscore_Gene2A : zscore from GTEx/cohort normalization for Gene2A
# zscore_Gene2B : zscore from GTEx/cohort normalization for Gene2B
# note_expression_Gene1A : differentially expressed or no change in expression for Gene1A
# note_expression_Gene1B : differentially expressed or no change in expression for Gene1B
# note_expression_Gene2A : differentially expressed or no change in expression for Gene2A
# note_expression_Gene2B : differentially expressed or no change in expression for Gene2B




suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("reshape2"))

option_list <- list(
  make_option(c("-S", "--standardFusionCalls"),type="character",
              help="Standardized fusion calls (.RDS) "),
  make_option(c("-z", "--zscoreFilter"), type="integer",default=2,
              help="zscore value to use as threshold for annotation of differential expression"),
  make_option(c("-e","--expressionMatrix"),type="character",
              help="expression matrix (TPM for samples that need to be zscore normalized .RDS)"),
  make_option(c("-c","--clinicalFile"),type="character",
              help="clinical file for all samples (.tsv)"),
  make_option(c("-y", "--cohortInterest"),type="character",
              help="cohorts of interest for the filtering"),
  make_option(c("-s","--saveZscoredMatrix"),type="character",
              help="path to save zscored matrix from GTEx normalization (.RDS)"),
  make_option(c("-n","--normalExpMatrix_path"),type="character",
              help="path to normal expression matrixes"),
  make_option(c("-m","--normalExpMatrix_match"),type="character",
              help="file containing the gtex normalized expression file to be used by each cohort and cancer group (.TSV"),
  make_option(c("-o","--outputFile"),type="character",
              help="Standardized fusion calls with additional annotation from GTEx zscore comparison (.TSV)")
)

opt <- parse_args(OptionParser(option_list=option_list))
standardFusionCalls<-opt$standardFusionCalls
expressionMatrix<-opt$expressionMatrix
zscoreFilter<- opt$zscoreFilter
saveZscoredMatrix<-opt$saveZscoredMatrix
clinicalFile <- opt$clinicalFile
cohortInterest<-unlist(strsplit(opt$cohortInterest,","))
normalExpMatrix_path<-opt$normalExpMatrix_path
normalExpMatrix_match<-opt$normalExpMatrix_match


# load standardaized fusion calls cohort
standardFusionCalls<-readRDS(standardFusionCalls)

# read in table that matches cohort + cancer_group with a certain normal group
normal_exp_match <- readr::read_tsv(normalExpMatrix_match)

# read in histologies file & filter to tumor + RNA-Seq
clinicalFile <- read.delim(clinicalFile, header = TRUE, sep = "\t", stringsAsFactors = FALSE) %>% 
  dplyr::filter(experimental_strategy == "RNA-Seq") 

# load expression Matrix for cohort
expressionMatrix<-readRDS(expressionMatrix) 

# get the list of normal GTEx expression matrix in the references folder
gtexMatrix <- list.files(normalExpMatrix_path)

ZscoredAnnotation<-function(standardFusionCalls=standardFusionCalls,
                            normData=normData, zscoreFilter=zscoreFilter,
                            saveZscoredMatrix=saveZscoredMatrix,cohort_BSids= cohort_BSids,
                            expressionMatrix=expressionMatrix){
  #  @param standardFusionCalls : Annotates standardizes fusion calls from callers [STARfusion| Arriba] or QC filtered fusion
  #  @param zscoreFilter : Zscore value to use as threshold for annotation of differential expression
  #  @param normData: normalizing expression dataset to calculate zscore
  #  @param expressionMatrix: Expression matrix associated with the fusion calls
  #  @param cohort_BSids: biospecimen ID for cohort of interest to filter/subset expression matrix
  #  @param saveZscoredMatrix: File to save zscored matrix calculated for the normalized data and expression matrix
  #  @results : expression_annotated_fusions is a standardized fusion call set with standard
              # column headers with additional columns below from expression annotation
              # zscore_Gene1A : zscore from GTEx normalization for Gene1A
              # zscore_Gene1B : zscore from GTEx normalization for Gene1B
              # zscore_Gene2A : zscore from GTEx normalization for Gene2A
              # zscore_Gene2B : zscore from GTEx normalization for Gene2B
              # note_expression_Gene1A : differentially expressed or no change in expression for Gene1A
              # note_expression_Gene1B : differentially expressed or no change in expression for Gene1B
              # note_expression_Gene2A : differentially expressed or no change in expression for Gene2A
              # note_expression_Gene2B : differentially expressed or no change in expression for Gene2B

  # fusion calls
  fusion_sample_gene_df_matched <- standardFusionCalls %>%
    # filter the fusion results to contain only samples in the cohort of interest
    dplyr::filter(Sample %in% cohort_BSids) %>%
    # We want to keep track of the gene symbols for each sample-fusion pair
    dplyr::select(Sample, FusionName, Gene1A, Gene1B, Gene2A, Gene2B) %>%
    # We want a single column that contains the gene symbols
    tidyr::gather(Gene1A, Gene1B, Gene2A, Gene2B,
                  key = gene_position, value = GeneSymbol) %>%
    # Remove columns without gene symbols
    dplyr::filter(GeneSymbol != "") %>%
    dplyr::arrange(Sample, FusionName) %>%
    # Retain only distinct rows
    dplyr::distinct()
    
    # gather the sample list 
    fusion_sample_list <- fusion_sample_gene_df_matched$Sample %>% unique()
    
    expressionMatrixMatched <- expressionMatrix  %>%
      select(cohort_BSids) %>%
      select(fusion_sample_list) 
    
    
    # remove 0s 
    expressionMatrixMatched<-expressionMatrixMatched[rowMeans(expressionMatrixMatched)!=0,]
    # log2 transformation
    expressionMatrixMatched<-log2(expressionMatrixMatched+1)
  
    # convert the expression data to data matrix
    normData_matched <- normData_matched %>% data.frame() %>%
      as.matrix()

    # rearrange to order with expressionMatrix
    normData_matched <- normData_matched[rownames(expressionMatrixMatched), ]
    # log2 transformation
    normData_matched <- log2(normData_matched + 1)
    #normData_matched mean and sd
    normData_means <- rowMeans(normData_matched, na.rm = TRUE)
    normData_sd <- apply(normData_matched, 1, sd, na.rm = TRUE)
    
    # subtract mean
    expressionMatrixzscored <- sweep(expressionMatrixMatched, 1, normData_means, FUN = "-")
    # divide by SD remove NAs and Inf values from zscore for genes with 0 in normData
    expressionMatrixzscored <- sweep(expressionMatrixzscored, 1,normData_sd, FUN = "/") %>% mutate(GeneSymbol=rownames(.)) %>% na_if(Inf) %>% na.omit()
  
  
    # To save GTEx/cohort scored matrix
    if(!missing(saveZscoredMatrix)){
      saveRDS(expressionMatrixzscored,saveZscoredMatrix)
    }
    # get long format to compare to expression
    expression_long_df <- expressionMatrixzscored %>%
      # Get the data into long format
      reshape2::melt(variable.name = "Sample",
                     value.name = "zscore_value") 
  
   # check columns for Gene1A,Gene2A,Gene1B and Gene2B
   cols<-c(Gene1A=NA, Gene1B=NA, Gene2A=NA, Gene2B=NA)
  
     expression_annotated_fusions <- data.frame()
     for (i in 1:length(fusion_sample_list)){
       matched_sample <- fusion_sample_list[i]
       fusion_sample_matched <- fusion_sample_gene_df_matched %>% filter(Sample == matched_sample)
       expression_sample_matched <- expression_long_df %>% filter(Sample == matched_sample)
       expression_annotated_fusion_individual <- fusion_sample_matched %>%
         # join the filtered expression values to the data frame keeping track of symbols
         # for each sample-fusion name pair
         dplyr::left_join(expression_sample_matched, by = c("Sample", "GeneSymbol")) %>%
         # for each sample-fusion name pair, are all genes under the expression threshold?
         dplyr::group_by(FusionName, Sample) %>%
         dplyr::select(FusionName, Sample,zscore_value,gene_position) %>%
         # cast to keep zscore and gene position
         reshape2::dcast(FusionName+Sample ~gene_position,value.var = "zscore_value") %>%
         # incase Gene2A/B dont exist like in STARfusion calls
         add_column(!!!cols[setdiff(names(cols),names(.))]) %>%
         # get annotation from z score
         dplyr::mutate(note_expression_Gene1A = ifelse((Gene1A>zscoreFilter| Gene1A< -zscoreFilter),"differentially expressed","no change"),
                       note_expression_Gene1B = ifelse((Gene1B>zscoreFilter| Gene1B< -zscoreFilter),"differentially expressed","no change"),
                       note_expression_Gene2A = ifelse((Gene2A>zscoreFilter| Gene2A< -zscoreFilter),"differentially expressed","no change"),
                       note_expression_Gene2B = ifelse((Gene2B>zscoreFilter| Gene2B< -zscoreFilter),"differentially expressed","no change")) %>%
         dplyr::rename(zscore_Gene1A=Gene1A,
                       zscore_Gene1B=Gene1B,
                       zscore_Gene2A=Gene2A,
                       zscore_Gene2B=Gene2B) %>%
         # unique FusionName-Sample rows
         # use this to filter the QC filtered fusion data frame
         dplyr::inner_join(standardFusionCalls, by = c("FusionName", "Sample")) %>%
         dplyr::distinct()
       expression_annotated_fusions <- rbind(expression_annotated_fusions, expression_annotated_fusion_individual)
     }
  return (expression_annotated_fusions)
}

GTExZscoredAnnotation_filtered_fusions <- data.frame()
for (j in (1:length(gtexMatrix))) {
  # find the cohort + cancer_group that match to this particuarl gtexMatrix
  normal_matrix_name <- gtexMatrix[j]
  cohort_matched <- normal_exp_match %>% dplyr::filter(gtex_matrix == normal_matrix_name) %>% 
    dplyr::filter(cohort %in% cohortInterest) %>% dplyr::select(cohort,cancer_group) %>% distinct()
  cohort_list <- cohort_matched$cohort %>% unique()
  
  # find the BSids that are associated with all the above combinations of cohort + cancer_group
  cohort_BSids <-data.frame()
  for (k in (1:nrow(cohort_matched))){
    each_set <- clinicalFile %>% dplyr::filter(cohort == as.character(cohort_matched[k,1])) %>% 
      dplyr::filter(cancer_group == as.character(cohort_matched[k,2])) %>%
      dplyr::select(Kids_First_Biospecimen_ID) 
    cohort_BSids <- rbind(cohort_BSids, each_set)
  }
  # add some of them have cancer_group as NA, those needed to be added back
  cohort_BSids <- clinicalFile %>% dplyr::filter(cohort %in% cohort_list) %>%
    filter(is.na(cancer_group)) %>% dplyr::select(Kids_First_Biospecimen_ID) %>%
    rbind(cohort_BSids)
  # get the list of BSids that matches to the same normal matrix
  cohort_BSids <- cohort_BSids %>% pull(Kids_First_Biospecimen_ID)
  
  # read in the normData that matches with the cohort + cancer_group by normal_matrix_name
  normal_matrix_file_path <- file.path(normalExpMatrix_path, normal_matrix_name)
  normData_matched <- readRDS(normal_matrix_file_path)
  
  GTExZscoredAnnotation_filtered_fusions_individual <-ZscoredAnnotation(standardFusionCalls,zscoreFilter,normData=normData_matched,cohort_BSids=cohort_BSids, expressionMatrix = expressionMatrix)
  GTExZscoredAnnotation_filtered_fusions <- rbind(GTExZscoredAnnotation_filtered_fusions, GTExZscoredAnnotation_filtered_fusions_individual)
  }

# there are cohort+cancer_group that does not have associated gtex normal data
# for those specimens, we will add 'NA's to the zscore-related columns and combine that the rest
# this is needed since for next step, we are using the zscored annotated files as input so we need to
# combine those

no_normal_matrix <- normal_exp_match %>% dplyr::filter(gtex_matrix == "not available") %>% dplyr::select(cohort,cancer_group) %>% distinct()
no_normal_BSids <-data.frame()
for (p in (1:nrow(no_normal_matrix))){
  each_set <- clinicalFile %>% dplyr::filter(cohort == as.character(no_normal_matrix[p,1])) %>% 
    dplyr::filter(cancer_group == as.character(no_normal_matrix[p,2])) %>%
    dplyr::select(Kids_First_Biospecimen_ID) 
  no_normal_BSids <- rbind(no_normal_BSids, each_set)
}
no_normal_BSids <-  no_normal_BSids %>% pull(Kids_First_Biospecimen_ID)

# fusion calls
fusion_sample_gene_df_no_normal <- standardFusionCalls %>% 
  dplyr::filter(Sample %in% no_normal_BSids) %>%
  # We want to keep track of the gene symbols for each sample-fusion pair
  dplyr::select(Sample, FusionName, Gene1A, Gene1B, Gene2A, Gene2B) %>%
  # We want a single column that contains the gene symbols
  tidyr::gather(Gene1A, Gene1B, Gene2A, Gene2B,
                key = gene_position, value = GeneSymbol) %>%
  # Remove columns without gene symbols
  dplyr::filter(GeneSymbol != "") %>%
  dplyr::arrange(Sample, FusionName) %>%
  # Retain only distinct rows
  dplyr::distinct()

no_normal_matrix_zscored <- fusion_sample_gene_df_no_normal %>% dplyr:: mutate(note_expression_Gene1A = NA,
                                                                               note_expression_Gene1B = NA,
                                                                               note_expression_Gene2A = NA,
                                                                               note_expression_Gene2B = NA, 
                                                                               zscore_Gene1A=NA,
                                                                               zscore_Gene1B=NA,
                                                                               zscore_Gene2A=NA,
                                                                               zscore_Gene2B=NA)
GTExZscoredAnnotation_filtered_fusions <- rbind(GTExZscoredAnnotation_filtered_fusions, no_normal_matrix_zscored)
saveRDS(GTExZscoredAnnotation_filtered_fusions,paste0(opt$outputFile,"_GTExComparison_annotated.RDS"))
