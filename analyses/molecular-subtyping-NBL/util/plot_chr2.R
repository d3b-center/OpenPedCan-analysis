#Adapting the plot function from
# https://github.com/PediatricOpenTargets/OpenPedCan-analysis/blob/785c3224de29f701b1c1b62841d0f84d46f7eaca/analyses/molecular-subtyping-embryonal/03-clean-c19mc-data.Rmd#L56-L112


# Apply this code to chromosome 2 since MYCN is on Chromosome 2

plot_chr2 <- function(cn_df, biospecimen_id) {
  # This function takes a seg data.frame and a biospecimen identifier and 
  # returns a plot of the chromosome 2 segment mean for that biospecimen.
  # It fills missing seg.mean values with zeroes.
  # 
  # Args:
  #   cn_df: data.frame in SEG format
  #   biospecimen_id: A Kids First Biospecimen ID used to filter cn_df
  # 
  # Returns: essentially a barplot of the non-neutral segment means
  
  bsid_data <- cn_df %>%  
    # For visualization purposes fill the missing seg.mean values with zeroes
    tidyr::replace_na(list(seg.mean = 0)) %>%
    # Reformat the chromosome variable to drop the "chr"
    dplyr::mutate(chrom = factor(gsub("chr", "", chrom), 
                                 levels = c(1:22, "X", "Y"))) %>%
    # Only look at chr2 in the relevant sample
    filter(ID == biospecimen_id,
           chrom == 2) %>%
    # Make Del/Amp variable
    dplyr::mutate(Type = dplyr::case_when(
      seg.mean < 0 ~ "Del",
      seg.mean > 0 ~ "Amp",
      seg.mean == 0 ~ "Neutral"
    ))
  
  # Turn into a GRanges for easier mapping
  bsid_ranges <- GenomicRanges::GRanges(
    seqnames = bsid_data$chrom,
    ranges = IRanges::IRanges(
      start = bsid_data$loc.start,
      end = bsid_data$loc.end
    ),
    score = bsid_data$seg.mean,
    mcols = bsid_data$Type
  )
  
  # Map this on a plot
  bsid_plot <- 
    ggbio::autoplot(bsid_ranges,
                    ggplot2::aes(y = score, fill = mcols),
                    geom = "bar") +
    ggplot2::theme_bw() +
    ggplot2::ylim(c(-2, 2)) +
    colorblindr::scale_fill_OkabeIto(name = "Type") +
    ggplot2::labs(
      title = paste(biospecimen_id, "chr2"),
      y = "segment mean",
      x = "position"
    )
  return(bsid_plot)
}