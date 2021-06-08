# load histology df and count df ------------------------------------------
htl_df <- read.delim('../../data/histologies.tsv',
                     stringsAsFactors = FALSE, sep = '\t',
                     header=TRUE)

pb_kf_cnt_df <- readRDS(
    '../../data/gene-counts-rsem-expected_count-collapsed.rds')

# table(htl_df[htl_df$Kids_First_Biospecimen_ID %in% colnames(pb_kf_cnt_df),
#              'cohort'])
# 
# table(htl_df[htl_df$Kids_First_Biospecimen_ID %in% colnames(pb_kf_cnt_df),
#              'short_histology'])

gt_ta_tc_cnt_df <- readRDS(
    '../../data/gtex_target_tcga-gene-counts-rsem-expected_count-collapsed.rds')

# input sample ID mapping shared by @komalsrathi at 
# <https://github.com/PediatricOpenTargets/ticket-tracker/issues/22#
#      issuecomment-854900493>
kfbid_colid_mapping_df_list <- list(
    gtex = read.table('input/gtex_mapping.txt', sep = '\t', header = TRUE,
                      stringsAsFactors = FALSE),
    target = read.table('input/target_mapping.txt', sep = '\t', header = TRUE,
                        stringsAsFactors = FALSE),
    tcga = read.table('input/tcga_mapping.txt', sep = '\t', header = TRUE,
                      stringsAsFactors = FALSE)
)
# merge all mapping dfs
kfbid_colid_mapping_mdf <- do.call(rbind, kfbid_colid_mapping_df_list)
rownames(kfbid_colid_mapping_mdf) <- NULL

# Steps:
# 1. select unique sample IDs
# 2. subset expected count matrix
# 3. DGE testing

# merged df has the same number of rows
stopifnot(identical(
    sum(sapply(kfbid_colid_mapping_df_list, nrow)),
    nrow(kfbid_colid_mapping_mdf)))
# # sample barcodes are not unique
# stopifnot(identical(length(kfbid_colid_mapping_mdf$sample_barcode),
#                     length(unique(kfbid_colid_mapping_mdf$sample_barcode))))
dup_brcds <- kfbid_colid_mapping_mdf$sample_barcode[
    duplicated(kfbid_colid_mapping_mdf$sample_barcode)]
dup_brcd_df <- kfbid_colid_mapping_mdf[
    kfbid_colid_mapping_mdf$sample_barcode %in% dup_brcds, ]
dup_brcd_df <- dup_brcd_df[order(dup_brcd_df$sample_barcode), ]
dup_brcd_df$rsem_expected_cnt_colSum <- colSums(
    gt_ta_tc_cnt_df[, dup_brcd_df$sample_id])
dup_brcd_df$remove <- duplicated(
    dup_brcd_df[, c('sample_barcode', 'rsem_expected_cnt_colSum')])
dup_rm_sample_ids <- dup_brcd_df$sample_id[dup_brcd_df$remove]

rmdup_kfbid_colid_mapping_mdf <- kfbid_colid_mapping_mdf[
    !(kfbid_colid_mapping_mdf$sample_id %in% dup_rm_sample_ids), ]

# sample_ids are unique
stopifnot(identical(length(kfbid_colid_mapping_mdf$sample_id),
                    length(unique(kfbid_colid_mapping_mdf$sample_id))))

# htl_df Kids_First_Biospecimen_ID are not unique
# duplicated Kids_First_Biospecimen_IDs
dup_bids <- htl_df$Kids_First_Biospecimen_ID[
    duplicated(htl_df$Kids_First_Biospecimen_ID)]
dup_bid_df <- htl_df[htl_df$Kids_First_Biospecimen_ID %in% dup_bids, ]
dup_bid_df <- dup_bid_df[order(dup_bid_df$Kids_First_Biospecimen_ID), ]
# TODO: new issue on duplicated rows

# col subset
htl_subset_colnames <- c('Kids_First_Biospecimen_ID', 'experimental_strategy',
                         'sample_type', 'cohort', 'broad_histology',
                         'short_histology', 'cancer_group', 'gtex_group',
                         'gtex_subgroup')

cs_htl_df <- htl_df[, htl_subset_colnames]
# sample_barcode matches the mapping files
colnames(cs_htl_df)[1] <- 'sample_barcode'
# remove duplicated sample_barcode
cs_htl_df <- cs_htl_df[!duplicated(cs_htl_df$sample_barcode), ]
stopifnot(identical(
    nrow(cs_htl_df),
    length(unique(htl_df$Kids_First_Biospecimen_ID))))

# add pbta kf sample in mapping df
stopifnot(all(!(colnames(pb_kf_cnt_df) %in%
                    rmdup_kfbid_colid_mapping_mdf$sample_id)))
stopifnot(all(!(colnames(pb_kf_cnt_df) %in%
                    rmdup_kfbid_colid_mapping_mdf$sample_barcode)))
stopifnot(identical(length(colnames(pb_kf_cnt_df)),
                    length(unique(colnames(pb_kf_cnt_df)))))

pb_kf_colid_df <- data.frame(sample_barcode = colnames(pb_kf_cnt_df),
                             sample_id = colnames(pb_kf_cnt_df),
                             stringsAsFactors = FALSE)

stopifnot(all(!(pb_kf_colid_df$sample_id %in%
                    rmdup_kfbid_colid_mapping_mdf$sample_id)))
stopifnot(all(!(pb_kf_colid_df$sample_barcode %in%
                    rmdup_kfbid_colid_mapping_mdf$sample_barcode)))

m_kfbid_sid_df <- rbind(pb_kf_colid_df, rmdup_kfbid_colid_mapping_mdf)

stopifnot(identical(nrow(m_kfbid_sid_df),
                    length(unique(m_kfbid_sid_df$sample_id))))



m_kfbid_sid_htl_df <- merge(
    m_kfbid_sid_df, cs_htl_df,
    all.x = TRUE, by = 'sample_barcode', sort = TRUE)

stopifnot(identical(sort(m_kfbid_sid_htl_df$sample_id),
                    sort(m_kfbid_sid_df$sample_id)))

# table(m_kfbid_sid_htl_df[m_kfbid_sid_htl_df$sample_id %in%
#                              colnames(pb_kf_cnt_df), 'cohort'])

# # gtex sample ids do not match biospecimen ids
# m_kfbid_sid_htl_df[
#     substr(m_kfbid_sid_htl_df$sample_barcode, 1, 4) == 'GTEX', ]
# table(substr(
#     m_kfbid_sid_htl_df[is.na(m_kfbid_sid_htl_df$cohort), 'sample_barcode'],
#     1, 5))

# subset and merge count df -----------------------------------------------
stopifnot(all(colnames(pb_kf_cnt_df) %in% m_kfbid_sid_htl_df$sample_id))
stopifnot(all(colnames(gt_ta_tc_cnt_df) %in%
                  c(dup_rm_sample_ids, m_kfbid_sid_htl_df$sample_id)))

cmn_genes <- intersect(rownames(pb_kf_cnt_df), rownames(gt_ta_tc_cnt_df))
# head(rownames(gt_ta_tc_cnt_df)[!rownames(gt_ta_tc_cnt_df) %in% cmn_genes])
# colSums(gt_ta_tc_cnt_df[!rownames(gt_ta_tc_cnt_df) %in% cmn_genes, 1:10]) /
#     colSums(gt_ta_tc_cnt_df[, 1:10])
# 
# colSums(pb_kf_cnt_df[!rownames(pb_kf_cnt_df) %in% cmn_genes, 1:10]) /
#     colSums(pb_kf_cnt_df[, 1:10])
m_cnt_df <- cbind(
    pb_kf_cnt_df[cmn_genes, ],
    gt_ta_tc_cnt_df[
        cmn_genes,
        colnames(gt_ta_tc_cnt_df) %in% m_kfbid_sid_htl_df$sample_id]
)

# save output and load in another R session, in order to reduce memory usage
saveRDS(m_cnt_df,
        '../../scratch/pbta_kf_gtex_target_tcga_rsem_expected_cnt_df.rds')
saveRDS(m_kfbid_sid_htl_df,
        '../../scratch/pbta_kf_gtex_target_tcga_histology_df.rds')
