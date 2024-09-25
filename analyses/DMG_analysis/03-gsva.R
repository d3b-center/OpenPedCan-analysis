library(GSVA)

## set directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
data_dir <- file.path(root_dir, "data", "v13")
subset_dir <- file.path(root_dir, "analyses", "DMG_analysis", "subset")
result_dir <- file.path(root_dir, "analyses", "DMG_analysis", "results")


## read histologies
hist <- read_tsv(file.path(data_dir, "histologies.tsv"))
selected_sample <- hist %>% 
  filter(grepl(c("DMG"), molecular_subtype))
onco_df <- read_tsv(file.path(result_dir, "df_for_oncoplot.tsv"))

## RNA
RNA <- read_rds(file.path(data_dir, "gene-expression-rsem-tpm-collapsed.rds"))
col_rna <- selected_sample %>% 
  filter(experimental_strategy == "RNA-Seq") %>% 
  select(Kids_First_Biospecimen_ID, match_id)
select_RNA_all <- RNA[, col_rna %>% pull(Kids_First_Biospecimen_ID)]
log_rna <- as.matrix(log2(select_RNA_all + 1))

## Hallmark gene
human_hallmark <- msigdbr::msigdbr(species = "Homo sapiens", 
                                   category = "H")

human_hallmark_twocols <- human_hallmark %>% 
  select(gs_name, gene_symbol)

human_hallmark_list <- base::split(
  human_hallmark_twocols$gene_symbol,
  list(human_hallmark_twocols$gs_name))

## annotation 
col_annotate <- col_rna %>% 
  left_join(onco_df %>% select(match_id, EGFR)) %>% 
  mutate(EGFR_mut = case_when(!is.na(EGFR) ~ "EGFR mutated", TRUE ~ "EGFR unmutated")) %>% 
  select(-match_id)

RNA_EGFR_un <- as.matrix(log_rna[, col_annotate %>% filter(EGFR_mut == "EGFR unmutated") %>% pull(Kids_First_Biospecimen_ID)])
RNA_EGFR <- as.matrix(log_rna[, col_annotate %>% filter(EGFR_mut == "EGFR mutated") %>% pull(Kids_First_Biospecimen_ID)])

## GSVA for all samples
Hallmark_gsea_score_all <- GSVA::gsva(expr = log_rna,
                                      gset.idx.list = human_hallmark_list,
                                      method = "gsva", 
                                      min.sz = 1, max.sz = 1500,
                                      parallel.sz = 8, 
                                      mx.diff = TRUE) 

colAnn <- ComplexHeatmap::HeatmapAnnotation(EGFR_mut = col_annotete$EGFR_mut, which = "col")
hm <- ComplexHeatmap::Heatmap(Hallmark_gsea_score_all, 
                              show_column_names = FALSE, top_annotation = colAnn, 
                              row_names_gp = grid::gpar(fontsize = 5.8),
                              name = "GSVA score")

pdf("GSVA.pdf", height = 10, width = 15)
ComplexHeatmap::draw(hm)
dev.off()

## GSVA on EGFR mutated and unmutated
Hallmark_gsea_score <- GSVA::gsva(expr = RNA_EGFR,
                                  gset.idx.list = human_hallmark_list,
                                  method = "gsva", 
                                  min.sz = 1, max.sz = 1500,
                                  parallel.sz = 8, 
                                  mx.diff = TRUE) 

Hallmark_gsea_score_un <- GSVA::gsva(expr = RNA_EGFR_un,
                                     gset.idx.list = human_hallmark_list,
                                     method = "gsva", 
                                     min.sz = 1, max.sz = 1500,
                                     parallel.sz = 8, 
                                     mx.diff = TRUE) 

ComplexHeatmap::Heatmap(Hallmark_gsea_score)
ComplexHeatmap::Heatmap(Hallmark_gsea_score_un)