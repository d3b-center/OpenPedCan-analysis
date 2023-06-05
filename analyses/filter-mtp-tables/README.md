## Filter MTP Tables

### Purpose
Remove `Ensembl (ESNG)` gene identifier in the OPenPedCan mutation frequency tables, including [SNV](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/snv-frequencies), [CNV](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/cnv-frequencies), [fusion](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/fusion-frequencies), and [Gene expression TPM](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/rna-seq-expression-summary-stats) tables that are not in [GENCODE v39 (Ensembl package 105)](http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_39/).


### Analysis scripts

### `run-filter-mtp-tables.sh`
This is a wrapper bash script for main anlysis notebook script, `01-filter-mtp-tables-for-current-gencode.Rmd` that coverts JSON mutation frequencies files to JSON Line (JSONL), compresses JSONL files, and deletes intermediate JSON files. All file paths set in this script relative to the module directory. Therefore, this script should always run as if it were being called from the directory it lives in, the module directory (`OpenPedCan-analysis/analyses/filter-mtp-tables`)

Usage:
```
bash run-filter-mtp-tables.sh
```

### `01-filter-mtp-tables-for-current-gencode.Rmd`
This R notebook filters SNV, CNV, fusion mutation frequencies, and long TPM tables to exclude Ensembl gene identifier that are not in `GENCODE v39 (Ensembl package 105)` and in `Open Targets deprecated gene list` , and lists identifiers filtered out. 

Usage:
```
Rscript -e "rmarkdown::render('01-filter-mtp-tables-for-current-gencode.Rmd', clean = TRUE)"
```

### `02-filter-mtp-tables-misc-updates.R`
This Rscripts perform miscellaneous updates on MTP table required by FNL. 

Usage:
```
Rscript --vanilla 02-filter-mtp-tables-misc-updates.R
```

### Input:
- `../snv-frequencies/results/gene-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `../snv-frequencies/results/variant-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `../cnv-frequencies/results/gene-level-cnv-consensus-annotated-mut-freq.tsv.gz`
- `../fusion-frequencies/results/putative-oncogene-fused-gene-freq.tsv.gz`
- `../fusion-frequencies/results/putative-oncogene-fusion-freq.tsv.gz`
- `../rna-seq-expression-summary-stats/results/long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz`
- `../rna-seq-expression-summary-stats/results/long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz`
- `../../data/input/gencode.v39.primary_assembly.annotation.gtf.gz"`
- `../../data/snv-consensus-plus-hotspots.maf.tsv.gz`
- `../../data/consensus_wgs_plus_cnvkit_wxs.tsv.gz`
- `../../data/fusion-putative-oncogenic.tsv`
- `../../data/histologies.tsv`
- `input/MTP_v11_InvalidENSG_20220831.txt`


### Results:
- `results/gene-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `results/gene-level-snv-consensus-annotated-mut-freq.jsonl.gz`
- `results/gene-level-snv-consensus-annotated-mut-freq_dropped_ensg.tsv.gz`
- `results/variant-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `results/variant-level-snv-consensus-annotated-mut-freq.jsonl.gz`
- `results/variant-level-snv-consensus-annotated-mut-freq_dropped_ensg.tsv.gz`
- `results/gene-level-cnv-consensus-annotated-mut-freq.tsv.gz`
- `results/gene-level-cnv-consensus-annotated-mut-freq.jsonl.gz`
- `results/gene-level-cnv-consensus-annotated-mut-freq_dropped_ensg.tsv.gz`
- `results/putative-oncogene-fused-gene-freq.tsv.gz`
- `results/putative-oncogene-fused-gene-freq.jsonl.gz`
- `results/putative-oncogene-fused-gene-freq_dropped_ensg.tsv.gz`
- `results/putative-oncogene-fusion-freq.tsv.gz`
- `results/putative-oncogene-fusion-freq.jsonl.gz`
- `results/putative-oncogene-fusion-freq_dropped_ensg.tsv.gz`
- `results/long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz`
- `results/long_n_tpm_mean_sd_quantile_group_wise_zscore.jsonl.gz`
- `long_n_tpm_mean_sd_quantile_group_wise_zscore_dropped_ensg.tsv.gz`
- `results/long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz`
- `results/long_n_tpm_mean_sd_quantile_gene_wise_zscore.jsonl.gz`
- `results/long_n_tpm_mean_sd_quantile_gene_wise_zscore_dropped_ensg.tsv.gz`
- `01-filter-mtp-tables-for-current-gencode.nb.html`

