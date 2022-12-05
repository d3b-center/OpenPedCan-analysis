# Mutation Frequencies and Gene Expression TPM Table Summary and QC Checks
 `01-frequencies-tables-checks.Rmd` performs summary and QC checks comparing the `current` and the `previous` OpenPedCan mutation frequencies tables, including [CNV](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/cnv-frequencies), [SNV](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/snv-frequencies), and [Fusion](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/fusion-frequencies). Results include the 1) number of patients and samples in each cohort, 2) cancer groups represented in multiple cohorts, 3) a subset of sorted top 50 records from a static cancer group (`Neuroblastoma`) that should not change, 4) changes in common columns among mutation frequencies tables with non-dynamic values.

`02-tpm-tables-checks.Rmd` performs summary and QC checks comparing the `current` and the `previous` OpenPedCan 
 [gene expression tpm tables](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/mtp-tables-qc-checks). Results include 1) number of samples in each cohort, 2) cancer groups represented in multiple cohorts, 3) a subset of sorted top 50 records from a static cancer group (`Neuroblastoma`) that should not change, 4) changes in common columns among gene expression TPM tables with non-dynamic values.

## General usage of scripts
#### `run_frequencies-tables-checks.sh`
This is a batch bash script for running the analysis scripts `01-frequencies-tables-checks.Rmd` and `02-tpm-tables-checks.Rmd` over multiple pairs (current/previous) of mutation frequencies and tpm tables. All file paths set in this script are relative to the module directory. Therefore, this script should always run as if it were being called from the directory it lives in, the module directory (`OpenPedCan-analysis/analyses/mtp-tables-qc-checks`).

```
bash run_frequencies-tables-checks.sh
```

#### 01-frequencies-tables-checks.Rmd
Performs summary and QC checks comparing the current and the previous OpenPedCan 
mutation frequencies tables

```
Rscript -e "rmarkdown::render(
            '01-frequencies-tables-checks.Rmd',
            params = list(
              current_table = '<current file directory/current mutation frequencies file>', 
              previous_table = '<previous file directory/previous mutation frequencies file>'),  
              output_file = '<output RMD notebook file name>',
              clean = TRUE)" 
```

#### 02-tpm-tables-checks.Rmd
Performs summary and QC checks comparing the current and the previous OpenPedCan 
gene expression tpm tables

```
Rscript -e "rmarkdown::render(
            '02-tpm-tables-checks.Rmd',
            params = list(
              current_table = '<current file directory/current mutation frequencies file>', 
              previous_table = '<previous file directory/previous mutation frequencies file>'),  
              output_file = '<output RMD notebook file name>',
              clean = TRUE)" 
```


## Analysis input files
Current and previous input mutation frequencies and gene expression tpm input files
- `current/gene-level-cnv-consensus-annotated-mut-freq.tsv.gz`
- `previous/gene-level-cnv-consensus-annotated-mut-freq.tsv.gz`
- `current/gene-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `previous/gene-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `current/gene-variant-snv-consensus-annotated-mut-freq.tsv.gz`
- `previous/gene-variant-snv-consensus-annotated-mut-freq.tsv.gz`
- `current/putative-oncogene-fused-gene-freq.tsv.gz`
- `previous/putative-oncogene-fused-gene-freq.tsv.gz`
- `current/putative-oncogene-fusion-freq.tsv.gz`
- `previous/putative-oncogene-fusion-freq.tsv.gz`
- `current/long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz`
- `previous/long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz`
- `current/long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz`
- `previous/long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz`

## Analysis output files
Results are similarly reported in both html notebooks and excel workbooks. Each excel workbook has sheet tabs with descriptive names of tables rendered in their corresponding html notebook. 
- `gene-level-cnv-consensus-annotated-mut-freq-checks.nb.html`
- `results/gene-level-cnv-consensus-annotated-mut-freq.xlsx`
- `gene-level-snv-consensus-annotated-mut-freq-checks.nb.html`
- `results/gene-level-snv-consensus-annotated-mut-freq.xlsx`
- `gene-variant-snv-consensus-annotated-mut-freq-checks.nb.html`
- `results/variant-level-snv-consensus-annotated-mut-freq.xlsx`
- `putative-oncogene-fused-gene-freq-checks.nb.html`
- `results/putative-oncogene-fused-gene-freq.xlsx`
- `putative-oncogene-fusion-freq-checks.nb.html`
- `results/putative-oncogene-fusion-freq.xlsx`
- `long_n_tpm_mean_sd_quantile_gene_wise_zscore_checks.nb.html`
- `results/long_n_tpm_mean_sd_quantile_gene_wise_zscore.xlsx`
- `long_n_tpm_mean_sd_quantile_group_wise_zscore_checks.nb.html`
- `results/long_n_tpm_mean_sd_quantile_group_wise_zscore.xlsx`
