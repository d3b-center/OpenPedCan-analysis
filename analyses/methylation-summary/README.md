# OpenPedCan Methylation Summary

## Purpose

Summarize preprocessed `Illumina Infinium HumanMethylation` methylation array measurements produced by the [OpenPedCan methylation-analysis module](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/pull/169). 


## Analysis

- Parse `Illumina Infinium HumanMethylation` array probe metadata from the preprocessed methylation measurements produced by the [OpenPedCan methylation-analysis module](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/pull/169) for all cancer types using `01-create-methylation-annotation-table.R` script to create array probe annotations (`results/methyl-probe-annotations.tsv.gz`) matching `GENCODE version 38 (Ensembl 104)` gene symbols and asocciated Ensembl IDs.
- Parse `Beta-values` and `M-values`  produced by the [OpenPedCan methylation-analysis module](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/pull/169) for preprocessed methylation samples of all cancer types using `02-create-methylation-matrices.R` script to create sample-probe methylation measurements matrices (`results/methyl-beta-values.rds` and `results/methyl-m-values.rds`). 
- Using `03-calculate-beta-quantiles.R` script and the methylation `Beta-values matrix`, calculate probe-level `quantiles` for each cancer type (cancer_group) within an OpenPedCan cohort (`results/methyl-probe-beta-quantiles.tsv.gz`). 
- Using `04-beta-tpm-correlation.R` script and the methylation `Beta-values matrix`, calculate probe-level `correlations` between `RNA-Seq TPM-values` and `Beta-values` for each cancer type (cancer_group) within an OpenPedCan cohort for patients who have both datasets (`results/methyl-probe-beta-tpm-correlations.tsv.gz`). Correlations for cohorts will have independent scripts becuase of the differences in how samples with patients in both RNA-Seq and methylation data are determined. 
- Summarize all results using `05-create-methylation-summary-table.R` and `06-methly-summary-tsv2jsonl.py` scripts into a methylation summary table (`results/methyl-beta-values-summary.rds`, `results/methyl-beta-values-summary.tsv.gz` and `results/methyl-beta-values-summary.jsonl.gz`) that will be utilized with OPenPedCan plotting API and displayed on the NCI MTP portal with the following columns:
    - **Gene_Symbol**: gene symbol
    - **targetFromSourceId**: Ensemble ID
    - **PMTL**: Is gene on PMTL (`Relevant Molecular Target`) 
    - **Dataset**: OpenPedCan `cohort` i.e., TARGET
    - **Disease**: OpenPedCan `cancer_group` from file i.e., Neuroblastoma
    - **diseaseFromSourceMappedId**: EFO ID of OpenPedCan `cancer_group`
    - **MONDO**: MONDO_ID of OpenPedCan `cancer_group`
    - **RNA_Correlation**: array probe-level correlation between `methylation Beta-values` and `RNA-Seq TPM values`
    - **Probe_ID**: `Illumina Infinium HumanMethylation` array probe ID for the CpG site
    - **Chromosome**: chromosome for CpG site eg. chr1
    - **Location**: genomic location of the CpG site
    - **Beta_Q1**: array probe-level Beta Q1 quantile
    - **Beta_Q2**: array probe-level Beta Q2 quantile
    - **Beta_Median**: array probe-level Beta Q3 quantile
    - **Beta_Q4**: array probe-level Beta Q4 quantile
    - **Beta_Q5**: array probe-level Beta Q5 quantile
    - **datatypeId**: Illumina_methylation_array
    - **chop_uuid**: generate UUID
    - **datasourceId**: chop_gene_level_methylation


## General usage of scripts
Analyses involving 850k arrays with large number of samples representing OPenPedCan cancer groups (as in the CBTN cohort) will require `~256gb` of memory to run successfully. In some instances the `system /tmp` is too small to hold temporary files generated during analysis by R scripts. Users are advised to create create a `./tmp` in the module directory then execute R script by prepending with TMP/TMPDIR environmental variable as illustrated in the wrapper module bash script, `run-methylation-summary.sh`.


#### `Required R packages`
```
- tidyverse
- rtracklayer
- data.table
- ids
```

#### `Required Python3 modules`
```
- re
- os
- sys
- csv
- gzip
- json
- numpy
- pandas
- pyreadr
- GitPython
- collections
```

#### `run-methylation-summary.sh`
This is a bash script wrapper for running analysis scripts in the module. All file paths set in this script relative to the module directory. Therefore, this script should always run as if it were being called from the directory it lives in, the module directory (`OpenPedCan-analysis/analyses/methylation-summary`).

```
bash run-methylation-summary.sh
```

#### `01-create-methylation-annotation-table.R`
This script creates combined probe annotations for preprocessed methylation arrays using GENCODE version 38 (Ensembl 104) gene symbols.

```
Rscript --vanilla 01-create-methylation-annotation-table.R
```

#### `02-create-methylation-matrices.R`
This script creates combined methylation `Beta-values` and `M-values` matrices for all cancer types.

```
Rscript --vanilla 02-create-methylation-matrices.R
```

#### `03-calculate-beta-quantiles.R`
This script calculates probe-level `Beta-value quantiles` for all cancer types.

```
Rscript --vanilla 03-calculate-beta-quantiles.R
```

#### `04-beta-tpm-correlation.py`
This script calculates representative probe-level `correlations` between `TPM-values` and `Beta-values` for patients who have both RNA-Seq and methylation sample datasets.
**Note:** Run times for this script is approximately 3 hours per cancer_group to calculate correlations for all preprocessed probes in the Illumina Infinium HumanMethylation 450k BeadArrays.

```
python3 04-beta-tpm-correlation.py
```

#### `05-create-methylation-summary-table.R`
This script creates Pediatric OpenTargets methylation summary table that will be utilized with OPenPedCan plotting API and displayed on the NCI MTP portal.

```
Rscript --vanilla 05-create-methylation-summary-table.R
```

#### `06-methly-summary-tsv2jsonl.py`
This script create a JSONL file for Pediatric OpenTargets methylation summary table utilized on NCI MTP portal.

```
python3 06-methly-summary-tsv2jsonl.py
```

## Input datasets
Methylation `beta-values` and `M-values` ar available on the CHOP HPC `Isilon` sever (location: `/mnt/isilon/opentargets/wafulae/methylation-analysis/results/`). Please contact `Avin Farrel (@afarrel)` for access if not already for dowbnload using the [OpenPedCan data release download script](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/blob/dev/download-data.sh). The modules requires the [v11 OpenPedCan histologies file](https://github.com/d3b-center/D3b-codes/pull/53) that includes the methylation array samples. 
- `../../data/TARGET-beta-values-methylation.tsv.gz`
- `../../data/TARGET-m-values-methylation.tsv.gz`
- `../../data/CBTN-beta-values-methylation.tsv.gz`
- `../../data/CBTN-m-values-methylation.tsv.gz` 
- `../../data/results/gencode.v38.primary_assembly.annotation.gtf.gz`
- `../../data/gene-expression-rsem-tpm-collapsed.rds`
- `../../data/efo-mondo-map.tsv`
- `../../data/histologies.tsv` (v11 release) 
- `../../data/ensg-hugo-pmtl-mapping.tsv.tsv`
- `input/UCSC_hg19-GRCh37_Ensembl2RefSeq.tsv` (Downloaded from UCSC Table Browser: https://genome.ucsc.edu/cgi-bin/hgTables)


## Results
Analysis result files sizes exceed the limit allowable to push on to a GitHub repository and are available on the CHOP HPC `Isilon` sever (location: `/mnt/isilon/opentargets/wafulae/methylation-summary/results/`). Please contact `Avin Ferrel (@afarrel)` for access.
- `results/methyl-probe-annotations.tsv.gz`
- `results/methyl-beta-values.rds`
- `results/methyl-beta-values.rds`
- `results/methyl-probe-beta-quantiles.tsv.gz`
- `results/methyl-probe-beta-tpm-correlations.tsv.gz`
- `results/methyl-beta-values-summary.rds` (for API DB loading)
- `results/methyl-beta-values-summary.tsv.gz` (for users download on MTP)
- `results/methyl-beta-values-summary.jsonl.gz` (for MTP DB loading)
