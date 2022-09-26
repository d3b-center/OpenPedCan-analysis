## Filter Mutation Frequencies Tables

### Purpose
Performs QC on data pre-release files with requirements which should pass before hand off between BIXU Engineering team to the OpenPedCan team.


### Analysis scripts

### `run-filter-mutation-frequencies-tables.sh`
This is a wrapper bash script for main anlysis notebook script, `data-pre-release-qc.Rmd`  This script should always run as if it were being called from the directory it lives in, the module directory (`OpenPedCan-analysis/analyses/data-pre-release-qc`)


Usage:
```bash
bash run-data-pre-release-qc.sh

```

### `data-pre-release-qc.Rmd`
Performs QC on data pre-release files 

Usage:
```r
Rscript -e "rmarkdown::render('data-pre-release-qc.Rmd', clean = TRUE)"
```

Pre-release files:
- `../../data/histologies.tsv`
- `../../data/gene-counts-rsem-expected_count-collapsed.rds`
- `../../data/gene-expression-rsem-tpm-collapsed.rds`
- `../../data/tcga-gene-counts-rsem-expected_count-collapsed.rds`
- `../../data/tcga-gene-expression-rsem-tpm-collapsed.rds`
- `../../data/cnv-cnvkit.seg.gz`
- `../../data/cnv-controlfreec.tsv.gz`
- `../../data/cnvkit_with_status.tsv`
- `../../data/consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz`
- `../../data/consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz`
- `../tmb-calculation/results/snv-mutation-tmb-all.tsv`
- `../tmb-calculation/results/snv-mutation-tmb-coding.tsv`
- `../fusion-summary/results/fusion_summary_embryonal_foi.tsv`
- `../fusion-summary/results/fusion_summary_ependymoma_foi.tsv`
- `../fusion-summary/results/fusion_summary_lgat_foi.tsv`
- `../fusion-summary/results/fusion_summary_ewings_foi.tsv`
- `../../data/biospecimen_id_to_bed_map.txt`


Results files:
- Results tables are rendered in the `data-pre-release-qc.nb.html` notebook and also write in the `results/` folder whenever QC requirements are not meet with output file name prepended with input pre-release file base name.  



