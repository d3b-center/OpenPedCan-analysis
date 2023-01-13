suppressPackageStartupMessages({
  library(GenomicRanges)
  library(dplyr)
})

process_annotate_overlaps <- function(cnv_df, exon_granges, gene_df) {
  # This function takes a standardized data.frame that contains genomic range
  # information (cnv_df) and finds the overlaps with a GRanges object (exon_granges). 
  #
  # Args:
  #   cnv_df: standardized data.frame that contains the segments used in the CNV caller
  #   exon_granges: exons to be merged with the CNV data.frame;
  #
  # Returns:
  #   A data.frame with the following columns: 
  #   biospecimen_id, status, copy_number, ploidy, ensembl, gene_symbol, cytoband
  
  # make CNV data.frame into GRanges and sort by coordinates
  cnv_gr <- cnv_df %>% 
    GenomicRanges::makeGRangesFromDataFrame(keep.extra.columns = TRUE, 
                                            starts.in.df.are.0based = FALSE) %>%
    sort()
  
  # Create a data.frame with the overlaps between the CNV file and Gencode exon coordinates
  query <- cnv_gr
  subject <- exon_granges[exon_granges@seqnames %in% query@seqnames] # subset to only sequences in query
  overlapping_ranges <- findOverlaps(query = query, subject = subject)
  overlapping_ranges <- data.frame(query[queryHits(overlapping_ranges),], subject[subjectHits(overlapping_ranges),]) 
  
  # Add exon-segment overlap width to overlapping_ranges
  overlapping_ranges$width.1 <- ifelse(overlapping_ranges$end.1 > overlapping_ranges$end, overlapping_ranges$width.1 - (overlapping_ranges$end.1 - overlapping_ranges$end),
                                      ifelse(overlapping_ranges$start.1 < overlapping_ranges$start, overlapping_ranges$width.1 - (overlapping_ranges$start - overlapping_ranges$start.1),
                                             overlapping_ranges$width.1))
  
  # Calculate sum of exon overlap width for each segment 
  overlapping_ranges$status <- addNA(overlapping_ranges$status)
  exon_overlap <- aggregate(overlapping_ranges$width.1, by = list(overlapping_ranges$seqnames, overlapping_ranges$start, overlapping_ranges$end, overlapping_ranges$Kids_First_Biospecimen_ID, 
                                                                 overlapping_ranges$gene_id), sum)
  names(exon_overlap) <- c('seqnames', 'start', 'end', 'biospecimen_id', 'ensembl', 'overlap_len')
  
  # calculate gene exon lengths gene_lens as sum of interval lengths in gene_df
  gene_lens <- aggregate(gene_df$end - gene_df$start + 1, by = list(ensembl = gene_df$gene_id), sum)
  names(gene_lens) <- c('ensembl', 'gene_len')
  
  # return object with specific columns and add exon overlap and gene_lens columns
  overlapping_ranges <- overlapping_ranges %>%
    dplyr::rename("biospecimen_id" = "Kids_First_Biospecimen_ID",
                  "ploidy" = "tumor_ploidy",
                  "ensembl" = "gene_id",
                  "gene_symbol" = "gene_name") %>%
    dplyr::select(seqnames, start, end, biospecimen_id, status, copy_number, ploidy, ensembl, gene_symbol, cytoband) %>%
    dplyr::distinct() %>%
    dplyr::left_join(exon_overlap, by = c('seqnames', 'start', 'end', 'biospecimen_id', 'ensembl')) %>%
    dplyr::left_join(gene_lens, by = 'ensembl') %>%
    dplyr::select(seqnames, biospecimen_id, status, copy_number, ploidy, ensembl, gene_symbol, cytoband, overlap_len, gene_len) 
  
  # calculate % gene exon overlap for each call
  overlapping_ranges <- overlapping_ranges %>%
    add_column(pct_overlap = overlapping_ranges$overlap_len/overlapping_ranges$gene_len * 100) %>%
    dplyr::select(seqnames, biospecimen_id, status, copy_number, ploidy, ensembl, gene_symbol, cytoband, pct_overlap) %>%
    arrange(biospecimen_id, gene_symbol)

  return(overlapping_ranges)
}