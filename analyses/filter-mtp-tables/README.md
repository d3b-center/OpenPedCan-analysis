## Filter MTP Tables
This analysis is DEPRECATED and was last run with OpenPedCan data release `v12`.

### Purpose
Remove `Ensembl (ESNG)` gene identifier and update EFO-MONO codes in the MTP tables, including [SNV](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/snv-frequencies), [CNV](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/cnv-frequencies), [fusion](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/fusion-frequencies), [Gene expression TPM](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/rna-seq-expression-summary-stats), [methylation summary](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/methylation-summary) and [tumor-normal-differential-expression](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/tumor-normal-differential-expression) based on the Open Targets Platform [Targets and Disease/Phenotype annotations](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/mtp-annotations).


### Analysis scripts

### `run-filter-mtp-tables.sh`
This is a wrapper bash script for main anlysis notebook script, `01-filter-mtp-tables-for-current-gencode.Rmd` that coverts JSON mutation frequencies files to JSON Line (JSONL), compresses JSONL files, and deletes intermediate JSON files. All file paths set in this script relative to the module directory. Therefore, this script should always run as if it were being called from the directory it lives in, the module directory (`OpenPedCan-analysis/analyses/filter-mtp-tables`)

Usage:
```
bash run-filter-mtp-tables.sh
```

### `01-filter-mtp-tables-for-current-gencode.Rmd`
This R notebook filters SNV, CNV, fusion mutation frequencies, long TPM tables, and methyl summary tables to exclude Ensembl gene identifiers and update EFO-MONDO codes based on the Open Targts Platform  annotations. 

Usage:
```
Rscript -e "rmarkdown::render('01-filter-mtp-tables-for-current-gencode.Rmd', clean = TRUE)"
```

### `02-mtp-tsv2jsonl.py`
This python scripts script converts mtp table from TSV format to JSONL

Usage:
```
usage: 02-mtp-tsv2jsonl.py [-h] [-v] MTP_TSV

positional arguments:
  MTP_TSV        MTP TSV file
                 
optional arguments:
  -h, --help     show this help message and exit
  -v, --version  Print the current 02-mtp-tsv2jsonl.py script version and exit
                 
```


### Input:
- `gene-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `variant-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `gene-level-cnv-consensus-annotated-mut-freq.tsv.gz`
- `putative-oncogene-fused-gene-freq.tsv.gz`
- `putative-oncogene-fusion-freq.tsv.gz`
- `long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz`
- `long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz`
- `gene-methyl-beta-values-summary.tsv.gz`
- `isoform-methyl-beta-values-summary.tsv.gz`
- `gene-counts-rsem-expected_count-collapsed-deseq.tsv.gz`
- `../../data/input/gencode.v38.primary_assembly.annotation.gtf.gz"`
- `../../data/snv-consensus-plus-hotspots.maf.tsv.gz`
- `../../data/consensus_wgs_plus_cnvkit_wxs.tsv.gz`
- `../../data/fusion-putative-oncogenic.tsv`
- `../../data/histologies.tsv`
- `../mtp-annotations/results/mtp-targets-mapping.tsv`
- `../mtp-annotations/results/mtp-diseases-mapping.tsv` (semi-manual updates)



### Results:
- `../../scratch/gene-level-cnv-consensus-annotated-mut-freq.jsonl.gz`
- `../../scratch/gene-level-cnv-consensus-annotated-mut-freq.tsv.gz`
- `../../scratch/gene-level-snv-consensus-annotated-mut-freq.jsonl.gz`
- `../../scratch/gene-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `../../scratch/gene-methyl-beta-values-summary.jsonl.gz`
- `../../scratch/gene-methyl-beta-values-summary.rds`
- `../../scratch/gene-methyl-beta-values-summary.tsv.gz`
- `../../scratch/isoform-methyl-beta-values-summary.jsonl.gz`
- `../../scratch/isoform-methyl-beta-values-summary.rds`
- `../../scratch/isoform-methyl-beta-values-summary.tsv.gz`
- `../../scratch/long_n_tpm_mean_sd_quantile_gene_wise_zscore.jsonl.gz`
- `../../scratch/long_n_tpm_mean_sd_quantile_gene_wise_zscore.tsv.gz`
- `../../scratch/long_n_tpm_mean_sd_quantile_group_wise_zscore.jsonl.gz`
- `../../scratch/long_n_tpm_mean_sd_quantile_group_wise_zscore.tsv.gz`
- `../../scratch/putative-oncogene-fused-gene-freq.jsonl.gz`
- `../../scratch/putative-oncogene-fused-gene-freq.tsv.gz`
- `../../scratch/putative-oncogene-fusion-freq.jsonl.gz`
- `../../scratch/putative-oncogene-fusion-freq.tsv.gz`
- `../../scratch/variant-level-snv-consensus-annotated-mut-freq.jsonl.gz`
- `../../scratch/variant-level-snv-consensus-annotated-mut-freq.tsv.gz`
- `results/gene-level-cnv-consensus-annotated-mut-freq_dropped_ensg.tsv.gz`
- `results/gene-level-snv-consensus-annotated-mut-freq_dropped_ensg.tsv.gz`
- `results/gene-methyl-beta-values-summary_dropped_ensg.tsv.gz`
- `results/isoform-methyl-beta-values-summary_dropped_ensg.tsv.gz`
- `results/long_n_tpm_mean_sd_quantile_gene_wise_zscore_dropped_ensg.tsv.gz`
- `results/long_n_tpm_mean_sd_quantile_group_wise_zscore_dropped_ensg.tsv.gz`
- `results/putative-oncogene-fused-gene-freq_dropped_ensg.tsv.gz`
- `results/putative-oncogene-fusion-freq_dropped_ensg.tsv.gz`
- `results/variant-level-snv-consensus-annotated-mut-freq_dropped_ensg.tsv.gz`
- `results/gene-counts-rsem-expected_count-collapsed-deseq_dropped_ensg.tsv.gz`
- `01-filter-mtp-tables-for-current-gencode.nb.html`

