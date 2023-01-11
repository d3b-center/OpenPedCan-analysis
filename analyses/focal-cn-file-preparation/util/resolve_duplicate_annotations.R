suppressPackageStartupMessages({
  library(GenomicRanges)
  library(dplyr)
  library(tidyverse)
})

resolve_duplicate_annotations <- function(overlap_annotation = overlap_annotation) {
  # This function takes a standardized data.frame output from the `process_annotate_overlaps.R` 
  # script and attempts to resolve duplicate gene cn calls using various criteria to retain 
  # only a single status call. 
  # 
  #
  # Args:
  #   overlap_annotation: standardized data.frame output from `process_annotate_overlaps()` function
  #
  # Returns:
  #   A data.frame with the following columns: 
  #   biospecimen_id, status, copy_number, ploidy, ensembl, gene_symbol, cytoband, pct_overlap
  #
  # where `pct_overlap` indicates the percent of the gene exonic regions overlapping by the segment
  
  # obtain status call ids including just biospecimen-ensembl gene id combinations, and a second id also including `status` and `copy_number`
  call_id1 <- paste(overlap_annotation$biospecimen_id, overlap_annotation$ensembl, sep = ':')
  call_id2 <- paste(overlap_annotation$biospecimen_id, overlap_annotation$ensembl, overlap_annotation$status, overlap_annotation$copy_number, sep = ':')

  # Define duplications with the same call as those duplicated in `call_id1` and `call_id2`, and those with conflicting calls as duplicated only in `call_id1`
  dup_same <- call_id1[duplicated(call_id1) & duplicated(call_id2)]
  dup_conf <- call_id1[duplicated(call_id1) & !duplicated(call_id2)]

  # define `unique_calls` data.frame to include all those calls that are either unique or duplicated but with same status:
  unique_calls <- overlap_annotation %>%
    filter(!call_id1 %in% dup_conf) %>%
    dplyr::select(biospecimen_id, status, copy_number, ploidy, ensembl, gene_symbol, cytoband, pct_overlap) %>%
    distinct(biospecimen_id, status, ensembl, .keep_all = T) %>%
    arrange(biospecimen_id, gene_symbol)

  # define `dup_calls` as those calls with conflicting statuses: 
  dup_calls <- overlap_annotation %>%
    filter(call_id1 %in% dup_conf) %>%
    dplyr::select(biospecimen_id, status, copy_number, ploidy, ensembl, gene_symbol, cytoband, pct_overlap)
  dup_calls$id = paste(dup_calls$biospecimen_id, dup_calls$ensembl, sep = ':')

  # Identify cases where one of two duplicate calls is NA: 
  dup_na <- dup_calls %>%
    filter(id %in% id[is.na(status)] & id %in% id[!is.na(status)])
  
  # Filter out these calls from duplicated calls: 
  dup_calls <- dup_calls %>%
    filter(!id %in% dup_na$id)
  
  # Add resolved calls to unique calls: 
  dup_na <- dup_na %>%
    filter(!is.na(dup_na$status)) %>%
    dplyr::select(-id)
  unique_calls <- suppressWarnings(bind_rows(unique_calls, dup_na))
  
  # Filter out duplicated calls with a 'neutral' status, and retain non-neutral call:
  dup_neut <- dup_calls %>%
    filter(status != 'neutral') %>%
    filter(!id %in% id[duplicated(id)])
  
  # remove these calls from duplicated calls: 
  dup_calls <- dup_calls %>%
    filter(!id %in% dup_neut$id & status != 'neutral' | is.na(status))
  
  ## Add resolved calls to unique calls: 
  dup_neut <- dup_neut %>%
    dplyr::select(-id)
  unique_calls <- suppressWarnings(bind_rows(unique_calls, dup_neut))
  
  ## Aggregate cases where there are >2 duplicated calls with two calls being the same
  if (nrow(dup_calls) > 0){
    dup_calls$status <- addNA(dup_calls$status)
    dup_calls <- aggregate(dup_calls$pct_overlap, 
                           by = list(biospecimen_id = dup_calls$biospecimen_id, status = dup_calls$status, copy_number = dup_calls$copy_number,
                                     ploidy = dup_calls$ploidy, ensembl = dup_calls$ensembl, gene_symbol = dup_calls$gene_symbol,
                                     cytoband = dup_calls$cytoband, id = dup_calls$id),
                           sum) %>%
      dplyr::rename('pct_overlap' = 'x')
    dup_calls <- dup_calls[order(dup_calls$biospecimen_id, dup_calls$ensembl),]
    
    # Pull calls that have been deduplicated
    dup_sameCall <- dup_calls %>%
      filter(id %in% names(table(id))[table(id) == 1])
    
    # remove these calls from duplicated calls
    dup_calls <- dup_calls %>%
      filter(!id %in% dup_sameCall$id)
    
    # Add resolved calls to unique calls: 
    dup_sameCall <- dup_sameCall %>%
      dplyr::select(-id)
    unique_calls <- suppressWarnings(bind_rows(unique_calls, dup_sameCall))
  }
  
  # Identify duplicate calls where one call exhibits > 50% exon overlap
  if (nrow(dup_calls) > 0){
    dup_major <- dup_calls %>%
      filter(id %in% id[pct_overlap>50]) %>%
      arrange(biospecimen_id, ensembl, desc(pct_overlap)) %>%
      distinct(id, .keep_all = T)
    
    # filter these calls from duplicated calls: 
    dup_calls <- dup_calls %>%
      filter(!id %in% dup_major$id) %>%
      arrange(biospecimen_id, ensembl, desc(pct_overlap))
    
    ## Add resolved calls to unique calls: 
    dup_major <- dup_major %>%
      dplyr::select(-id)
    unique_calls <- suppressWarnings(bind_rows(unique_calls, dup_major))
  }
  
  ## Identify duplicate calls where one call has >1.5x % exon overlap relative to call with next highest overlap
  if (nrow(dup_calls) > 0){
    max <- aggregate(dup_calls$pct_overlap, by= list(id = dup_calls$id), max)$x  
    second <- aggregate(dup_calls$pct_overlap, by= list(id = dup_calls$id), function(y) sort(y)[length(y) - 1])$x
    
    dup_15x <- dup_calls %>%
      filter(id %in% unique(id)[max > (1.5 * second)]) %>%
      arrange(biospecimen_id, ensembl, desc(pct_overlap)) %>%
      distinct(id, .keep_all = T)
    
    # remove resolved calls from duplicated calls
    dup_calls <- dup_calls %>%
      filter(!id %in% dup_15x$id)
    
    ## Add resolved calls to unique calls: 
    dup_15x <- dup_15x %>%
      dplyr::select(-id)
    unique_calls <- suppressWarnings(bind_rows(unique_calls, dup_15x))
  }
  
  # identify duplicate calls with same status but different copy number
  if (nrow(dup_calls) > 0){
    call_id <- paste(dup_calls$biospecimen_id, dup_calls$ensembl, dup_calls$status)  
    dup_sameStatus <- dup_calls %>%
      filter(call_id %in% call_id[duplicated(call_id)])
    
    # For duplicate calls with same status but different copy number, aggregate into a single row and include average copy_number and sum of % exon overlap 
    if (nrow(dup_sameStatus) > 0){
      dup_status <- aggregate(dup_sameStatus$copy_number, 
                              by = list(biospecimen_id = dup_sameStatus$biospecimen_id,
                                        status = dup_sameStatus$status,
                                        ploidy = dup_sameStatus$ploidy,
                                        ensembl = dup_sameStatus$ensembl,
                                        gene_symbol = dup_sameStatus$gene_symbol,
                                        cytoband = dup_sameStatus$cytoband,
                                        id = dup_sameStatus$id),
                              function(x) round(mean(x)))
      dup_status$pct_overlap <- aggregate(dup_sameStatus$pct_overlap, 
                                          by = list(biospecimen_id = dup_sameStatus$biospecimen_id,
                                                    status = dup_sameStatus$status,
                                                    ploidy = dup_sameStatus$ploidy,
                                                    ensembl = dup_sameStatus$ensembl,
                                                    gene_symbol = dup_sameStatus$gene_symbol,
                                                    cytoband = dup_sameStatus$cytoband,
                                                    id = dup_sameStatus$id),
                                          sum)$x

      # filter resolved calls from duplicated calls
      dup_calls <- dup_calls %>%
        filter(!id %in% dup_status$id)
      
      # add resolved calls to unique calls
      dup_status <- dup_status %>%
        dplyr::rename('copy_number' = 'x') %>%
        dplyr::select(biospecimen_id, status, copy_number, ploidy,
                      ensembl, gene_symbol, cytoband, pct_overlap)
      unique_calls <- suppressWarnings(bind_rows(unique_calls, dup_status))
    }
  }
  
  ## Identify amplification/gain and deep deletion/loss duplicate calls, and only retain amplification and deep deletion calls, respectively. 
  if (nrow(dup_calls) > 0){
    
#    dup_ampGain_delLoss <- dup_calls %>%
#      filter((id %in% id[status == 'gain'] & id %in% id[status == 'amplification']) | (id %in% id[status == 'loss'] & id %in% id[status == 'deep deletion'])) %>%
#      filter(status == 'amplification' | status == 'deep deletion')
    
    dup_ampGain_delLoss <- dup_calls %>%
      filter((id %in% id[status %in% c('gain', 'loss')] & id %in% id[status == 'amplification']) | (id %in% id[status %in% c('gain', 'loss')] & id %in% id[status == 'deep deletion'])) %>%
      filter(status == 'amplification' | status == 'deep deletion')
    
    # remove resolved calls from duplicated calls
    dup_calls <- dup_calls %>%
      filter(!id %in% dup_ampGain_delLoss$id) %>%
      arrange(biospecimen_id, ensembl, desc(pct_overlap))
    
    ## Add resolved calls to unique calls: 
    dup_ampGain_delLoss <- dup_ampGain_delLoss %>%
      dplyr::select(-id)
    unique_calls <- suppressWarnings(bind_rows(unique_calls, dup_ampGain_delLoss))
    
  }
  ## Add remaining unresolved calls to unique_calls data frame
#  dup_calls <- dup_calls %>%
#    dplyr::select(-id)
#  unique_calls <- suppressWarnings(unique_calls %>%
#    bind_rows(dup_calls) %>%
#    arrange(biospecimen_id, gene_symbol)) %>%
#    distinct(biospecimen_id, status, ensembl, .keep_all = T)

#  return(unique_calls)
  return(list(resolved_calls = unique_calls, 
              unresolved_calls = dup_calls))
}


