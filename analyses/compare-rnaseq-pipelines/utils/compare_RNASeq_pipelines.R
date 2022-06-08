# Invoke libraries
suppressPackageStartupMessages(
  {
    library(tidyr)
    library(dplyr)
  }
)

# This function performs quality check on expected RNA-Seq counts input  matrices for which correlation coefficient can be calculated
# Input: 2 matrices with RNA-seq counts processed by different pipelines
# Output: R list object containing 2 matrices
# Output_note: Each result matrix can be accessed as calc_cor_input[[mat1]]
# Output_note: , calc_cor_input[[mat2]]
qc_matrix_input <- function(matrix1, matrix2){
  #rownames must refer to gene names
  common_genes <- intersect(rownames(matrix1),rownames(matrix2)) %>%
    sort()
  mat1_all_genes <- matrix1[common_genes,]
  mat2_all_genes <- matrix2[common_genes,]
  
  #colnames must refer to sample ids
  common_samples <- intersect(colnames(mat1_all_genes), colnames(mat2_all_genes)) %>%
    sort()
  mat1_final <- mat1_all_genes[, common_samples]
  mat2_final <- mat2_all_genes[, common_samples]
  
  #Validate all rows/genes and all columns/sample_ids match across matrices
  mat1_col_extra <- setdiff(colnames(mat1_final),colnames(mat2_final))
  # character(0)
  mat2_col_extra <- setdiff(colnames(mat2_final),colnames(mat1_final))
  # character(0)
  
  calc_cor_input <- list(mat1_final,mat2_final)
  return(calc_cor_input)
  
}


# This function extracts gene level counts from each RNASeq workflow and calculates
# and returns a dataframe with 4 columns including gene_ids, and 
# correlation coefficient, standard error, and probable error of correlation coefficient
calculate_matrix_cor <- function(matrix1, matrix2, wf1_name, wf2_name){
  
  result_compare_all_genes <- data.frame()
  p1_p2_coef <- sapply(1:nrow(matrix1), function(i) cor(matrix1[i,], matrix2[i,]))
  print(paste("coef_length=",length(p1_p2_coef)))
  print(paste("m1_length=",length(rownames(matrix1)),"m2_length=",length(rownames(matrix2))))
  row_names <- rownames(matrix1)
  
  serr_r <- sapply(p1_p2_coef, function(r) (1 - (r^2))/length(p1_p2_coef))
  perr_r <- sapply(p1_p2_coef, function(r) 0.6745*((1 - (r^2))/sqrt(length(p1_p2_coef))))
  
  final_result <- data.frame()
  final_result <- cbind(row_names, p1_p2_coef, serr_r, perr_r)
  rownames(final_result) <- row_names
  colnames(final_result) <- c("gene_id", paste("coeff",wf1_name,wf2_name,sep = "_"), "stderr_coef", "proberr_coef")
  na.omit(final_result)
  return(final_result)
  
}
