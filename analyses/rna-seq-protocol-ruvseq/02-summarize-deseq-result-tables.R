suppressPackageStartupMessages(library(tidyverse))


print("Summarize DESeq2 result tables...")
# Function to read deseq2 result CSV table
read_deseq2_res_csv <- function(file_path) {
  # assert file_path is a length 1 character vector
  stopifnot(is.character(file_path))
  stopifnot(identical(length(file_path), as.integer(1)))

  # Read CSV and convert to tibble
  res_df <- read.csv(file_path, row.names = 1, stringsAsFactors = FALSE)
  res_tbl <- as_tibble(rownames_to_column(res_df, "gene_symbol"))
  # assert no NA in gene_symbol
  stopifnot(identical(sum(is.na(res_tbl$gene_symbol)), as.integer(0)))
  # assert no duplicates in gene_symbol
  stopifnot(identical(length(unique(res_tbl$gene_symbol)),
                      length(res_tbl$gene_symbol)))
  # Add p-value rank as suggested by @aadamk at
  # https://github.com/PediatricOpenTargets/OpenPedCan-analysis/pull/74
  # #issuecomment-891913653
  res_tbl <- mutate(res_tbl, PValue_asc_dense_rank = dense_rank(PValue))

  # Extract dataset, RUVg negative control gene set, and RUVg k values from file
  # paths
  de_params <- str_match(
    file_path,
    paste0(
      "^results/([^/]+)/([^/]+)/",
      "stranded_vs_polya_dge_(|ruvg_k\\d_)deseq2_nbinom_wald_test_res.csv$"))
  stopifnot(identical(sum(is.na(de_params)), as.integer(0)))

  # Add dataset, RUVg negative control gene set, and RUVg k value to column
  # names, except gene_symbol
  res_tbl <- rename(res_tbl, BH_FDR = BH.FDR)
  res_tbl <- rename_at(
    res_tbl, vars(-matches("gene_symbol")),
    function(cn) {
      if (identical(de_params[1, 4], "")) {
        ruvg_id <- "no_ruvg_batch_effect_estimation"
      } else {
        ruvg_id <- paste0(
          de_params[1, 4], str_replace_all(de_params[1, 2], "-", "_"))
      }
      dataset_id <- paste0(de_params[1, 3])
      return(paste(cn, dataset_id, ruvg_id, sep = "_"))
    })
  return(res_tbl)
}

# Get paths to all DESeq2 result CSV files
de_csv_paths <- Sys.glob("results/*/*/*.csv")
de_csv_tbl_list <- lapply(de_csv_paths, read_deseq2_res_csv)
merged_de_csv_tbl <- reduce(
  de_csv_tbl_list,
  function(x, y) {
    if (all(colnames(y) %in% colnames(x))) {
      # y columns are already merged in x
      return(x)
    } else {
      # assert none of the colnames(y) is in colnames(x), except gene_symbol
      stopifnot(all(!colnames(select(y, -gene_symbol)) %in% colnames(x)))
      return(inner_join(x, y, by = "gene_symbol"))
    }
  },
  .dir = "forward"
)

# Reorder columns
merged_de_csv_tbl <- merged_de_csv_tbl[, sort(colnames(merged_de_csv_tbl))]
merged_de_csv_tbl <- select(
  merged_de_csv_tbl, gene_symbol, starts_with("PValue"), starts_with("BH"),
  everything())

# Pull genes of interest up
house_keeping_atlas_genes <- read.csv(
  file.path(
    "..", "rna-seq-protocol-dge", "input", "Housekeeping_GenesHuman.csv"),
  sep = ";", stringsAsFactors = FALSE)
house_keeping_atlas_genes <- unique(house_keeping_atlas_genes$Gene.name)
# Suggested by @aadamk at
# https://github.com/PediatricOpenTargets/OpenPedCan-analysis/pull/74
# #issuecomment-891913653
polya_stranded_tech_diff_genes <- c(
  "MALAT1", "NEAT1", "HBA2", "MTATP6P1", "RN7SL3", "RN7SL2", "SNORD3A", "IGHA1",
  "IGHA2", "IGHM", "IGKC", "MTATP6P1", "MTATP6", "HIST1H1B", "HIST1H1C",
  "HIST1H1D", "HIST1H1E", "HIST1H2AB", "HIST1H2AC", "HIST1H2AG", "HIST1H2AH",
  "HIST1H2AJ", "HIST1H2AK", "HIST1H2AL", "HIST1H2BB", "HIST1H2BC", "HIST1H2BD",
  "HIST1H2BE", "HIST1H2BF", "HIST1H2BG", "HIST1H2BH", "HIST1H2BI", "HIST1H2BJ",
  "HIST1H2BK", "HIST1H2BL", "HIST1H2BM", "HIST1H2BN", "HIST1H2BO", "HIST1H3A",
  "HIST1H3B", "HIST1H3C", "HIST1H3E", "HIST1H3F", "HIST1H3G", "HIST1H3H",
  "HIST1H3I", "HIST1H3J", "HIST1H4A", "HIST1H4B", "HIST1H4C", "HIST1H4D",
  "HIST1H4E", "HIST1H4F", "HIST1H4H", "HIST1H4I", "HIST1H4L", "HIST2H2AB",
  "HIST2H2AC", "HIST2H2AE", "HIST2H2AF", "HIST2H3D", "HIST3H2A", "HIST3H2BB",
  "HIST4H4")
goi_vec <- unique(c(house_keeping_atlas_genes, polya_stranded_tech_diff_genes))
goi_vec <- sort(goi_vec[goi_vec %in% merged_de_csv_tbl$gene_symbol])

output_merged_de_csv_tbl <- bind_rows(
  filter(merged_de_csv_tbl, gene_symbol %in% goi_vec),
  filter(merged_de_csv_tbl, !gene_symbol %in% goi_vec)
)

write_tsv(
  output_merged_de_csv_tbl,
  "results/de_result_summary_table.tsv")

print("Done running 02-summarize-deseq-result-tables.R.")
