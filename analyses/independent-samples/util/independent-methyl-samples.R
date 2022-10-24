# independent-methyl-samples.R

#' Generate a vector of unique methylation samples
#' 
#' The samples from this function will be unique with respect to participants
#' i.e. only no two samples will come from the same participant. The input list 
#' should be pre-filtered by `composition` and `sample_type`.  
#' 
#' 
#' @param independent_rna_sample_df A data frame of samples, with columns 
#' corresponding to those in produced by RNA independent samples scripts  
#' depending on what set of samples you need to include
#' @param histology_df A data frame of samples, with columns corresponding 
#' to those `histologies.tsv`
#' @param independent_level Designates whether we want to count independent samples in 
#' different cohorts as independent or not. "all-cohorts" consider the same sample
#' in different cohorts as the same sample and "each-cohort" consider the same sample
#' in different cohorts as "independent" (different). 
#' @param match_type Designates which type matching needs to be done. Options
#' are "independent_rna" to include only methyl samples that match the 
#' independent-specimens.rnaseqpanel sample set, 
#' "independent_rna_plus_only_methyl" to include samples that match the rna sample 
#' set plus include samples where only rna samples exists
#' "none" to include only rnaseq samples
#' @param tumor_description_methyl_only Tumor descriptors to select samples where
#' only methylation samples are available and will have no matching id in independent_rna_sample_df
#' Options are "primary" to select only primary/initial tumors. Primary tumors are defined as those designated "Initial CNS Tumor"+ "Primary Tumor".
#' "primary_plus" if you would like to select other non-initial tumor RNA-Seq sample if no 
#' initial tumor RNA-Seq sample exists
#' or "relapse" in select only relapse tumors. Relapse tumors are defined as those designated by "Recurrence", "Recurrent Tumor","Recurrent tumor","Progressive","Progressive Disease Post-Mortem" in `tumor_descriptor` field
#' @param seed An optional random number seed. 
#' 
#' @return a data frame of Participant and Specimen IDs, each present only once.


independent_methyl_samples <- function(independent_rna_sample_df = NULL, 
                                    histology_df,
                                    independent_level = c("each-cohort", "all-cohorts"),
                                    match_type = c("independent_rna", "independent_rna_plus_only_methyl", "none"),
                                    tumor_description_methyl_only = c("primary", "relapse", "primary_plus"),
                                    seed){
  match_type <- match.arg(match_type)
  tumor_description_methyl_only <- match.arg(tumor_description_methyl_only)
  independent_level <- match.arg(independent_level)
  if(!missing(seed)){set.seed(seed)}
  primary_descs <- c("Initial CNS Tumor", "Primary Tumor")
  relapse_descs <- c("Recurrence", "Progressive", "Progressive Disease Post-Mortem")
  
  # add rna-methy match_id column comprising of "Kids_First_Participant_ID" and "sample_id" to histology_df
  # because some Kids_First_Participant_ID might have more than one sample_id
  histology_df <- histology_df %>%
    dplyr::mutate(match_id = paste(Kids_First_Participant_ID, sample_id, sep = "_"))
  
  # Find sample set for the dna independent samples 
  # This will always be the included since in both the following
  # conditions "independent_rna" "independent_rna_plus_only_methyl"
  # 
  independent_rna <- histology_df %>%
    # include matched independent_methyl samples
    dplyr::filter(Kids_First_Participant_ID %in%
                    independent_rna_sample_df$Kids_First_Participant_ID)
  
  matched_methyl <- histology_df %>%
    # keep methyl from histology_df
    dplyr::filter(experimental_strategy == "Methylation",
                  # keep match_id that only present in independent_rna
                  match_id %in% independent_rna$match_id)
  
  matched_methyl_primary <- histology_df %>%
    # keep methyl from histology_df
    dplyr::filter(experimental_strategy == "Methylation",
                  tumor_descriptor %in% primary_descs,
                  match_id %in% independent_rna$match_id)
  
  matched_methyl_relapse <- histology_df %>%
    # keep methyl from histology_df
    dplyr::filter(experimental_strategy == "Methylation",
                  tumor_descriptor %in% relapse_descs,
                  match_id %in% independent_rna$match_id)
  
  # Here we are adding only initial only-methyl samples
  # since this will always be part of independent_rna_plus_only_rna
  # regardless tumor_description_methyl_only is "primary" OR "primary_plus"
  #
  if( match_type == "independent_rna_plus_only_methyl" & tumor_description_methyl_only == "primary") {
    # find sample set where we initial only-methyl samples
    only_methyl_primary <- histology_df %>% 
      # keep methyl from histology_df
      dplyr::filter(experimental_strategy == "Methylation",
                    tumor_descriptor %in% primary_descs,
                    # find and remove participants which have 
                    # matching rna samples in independent_rnaseqpanel
                    !Kids_First_Participant_ID %in% independent_rna$Kids_First_Participant_ID)
    
    # has methyl samples which match the independent samples provided plus methyl only sample which are primary tumors
    sample_df <- bind_rows(matched_methyl_primary, only_methyl_primary)
  }
  
  if( match_type == "independent_rna_plus_only_methyl" & tumor_description_methyl_only == "relapse") {
    # find sample set where we initial only-methyl samples
    only_methyl_relapse <- histology_df %>% 
      # keep methyl from histology_df
      dplyr::filter(experimental_strategy == "Methylation",
                    tumor_descriptor %in% relapse_descs,
                    # find and remove participants which have 
                    # matching rna samples in independent_rnaseqpanel
                    !Kids_First_Participant_ID %in% independent_rna$Kids_First_Participant_ID)
    
    # has methyl samples which match the independent samples provided plus methyl only sample which are primary tumors
    sample_df <- bind_rows(matched_methyl_relapse, only_methyl_relapse)
  }
  
  # Here we are adding only-methyl samples which are not initial
  # if tumor_description_methyl_only == "primary_plus"
  #
  if(match_type == "independent_rna_plus_only_methyl" & tumor_description_methyl_only == "primary_plus"){
    # find sample set where we only find methyl samples
    only_methyl_primary <- histology_df %>% 
      # keep methyl from histology_df
      dplyr::filter(experimental_strategy == "Methylation",
                    tumor_descriptor %in% primary_descs,
                    # find and remove participants which have 
                    # matching rna samples in independent_rnaseqpanel
                    !Kids_First_Participant_ID %in% independent_rna$Kids_First_Participant_ID)
    only_methyl_plus <- histology_df %>% 
      # keep methyl from histology_df
      dplyr::filter(experimental_strategy == "Methylation",
                    # find and remove participants which have 
                    # matching rna samples in independent_rnaseqpanel
                    !Kids_First_Participant_ID %in% independent_rna$Kids_First_Participant_ID,
                    # and participant not in only_methyl_primary sample set
                    !Kids_First_Participant_ID %in% only_methyl_primary$Kids_First_Participant_ID
      )
    # has methyl samples which match the independent samples provided plus methyl only sample which are primary tumors plus methyl samples where no primary samples exists
    sample_df <- bind_rows(matched_methyl, only_methyl_primary, only_methyl_plus)
  } 
  
  if(independent_level == "each-cohort"){
    # find out the list of cohorts and cancer groups and loop through them to run the process for each cancer group and cohort
    # combination of cohort and cancer groups
    cohort_cancer_group_combo <- sample_df %>%
      dplyr::select(cohort, cancer_group) %>%
      unique() 
    
    independent_each <- data.frame(Kids_First_Participant_ID = character(), 
                                   Kids_First_Biospecimen_ID = character(), 
                                   stringsAsFactors = FALSE)
    
    # loop through each cohort and cancer group and combine the results together
    for(i in 1:nrow(cohort_cancer_group_combo)){
      # filter to the specific cancer group and cohort
      cohort_name <- cohort_cancer_group_combo[i,1] %>% as.character()
      cancer_group_name <- cohort_cancer_group_combo[i,2] %>% as.character()
      
      # deal with cancer group is NA to avoid missing samples
      if(is.na(cancer_group_name)){
        filtered_df <- sample_df %>% 
          dplyr::filter(cohort == cohort_name) %>%
          dplyr::filter(is.na(cancer_group))
      }else{
        filtered_df <- sample_df %>% 
          dplyr::filter(cohort == cohort_name) %>%
          dplyr::filter(cancer_group == cancer_group_name)
      }
      
      # find the independent samples for the specific cancer group and cohort
      # "If there are multiple rows for a given combination of inputs, only the first
      # row will be preserved. If omitted, will use all variables." -- distinct in dplyr 0.8.3
      independent_filtered <- filtered_df %>%
        dplyr::distinct(Kids_First_Participant_ID, .keep_all = TRUE) %>%
        dplyr::select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, 
                      cohort, cancer_group, experimental_strategy, tumor_descriptor)
      
      
      # merge the independent samples together
      independent_each <- rbind(independent_each, independent_filtered)
    }
    return(independent_each)
  }
  
  if(independent_level == "all-cohorts"){
    
    independent_all <- sample_df %>%
      dplyr::distinct(Kids_First_Participant_ID, .keep_all = TRUE) %>%
      dplyr::select(Kids_First_Participant_ID, Kids_First_Biospecimen_ID, 
                    cohort, cancer_group, experimental_strategy, tumor_descriptor)
    
    return(independent_all)
  }
  
}




