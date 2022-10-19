
## Description

This module describes the steps to download a filtered MTP tables from the Open Targets S3 bucket, followed by replacing the EFO code for Wilms tumor from `MONDO_0006058` to `MONDO_0019004`.

### Files
`update_EFO_MTP_filtered_tables.sh` : This script downloads the below listed MTP tables from the Open Targets S3 bucket, and then runs the R script `update_EFO_MTP_filtered_tables.R`. This script also converts the resulting TSV and JSON files to JSONL and compressed gz files which can be uploaded to the same S3 location. 

`update_EFO_MTP_filtered_tables.R`: This script performs the intended EFO code replacement and creates new tsv and json files with the updated data.

`long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz` and `long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz` : These files were extracted from the `analyses/rna-seq-expr-summary-stats/results`. Since this module was recently updated and merged to the OPC repo, these files are not yet available on the OT S3 bucket for the script to download and thus automate the processing. 

### Steps:

 - Download the bash script, R script
 - Copy the below files from `analyses/rna-seq-expr-summary-stats` into working directory 
  `long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz`, `long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz`
 - Execute the bash script as below:
	 `bash update_EFO_MTP_filtered_tables.sh`
 - Upload the final set of 14 (7 TSV and 7 JSONL) gz files to Open Targets S3 bucket


### Note: 
This PR must not be merged. This files must be executed locally and uploaded back to S3 bucket manually.