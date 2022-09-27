## Annotate CNV table with mutation frequencies

Adapted from [snv-frequencies](https://github.com/logstar/OpenPedCan-analysis/tree/snv-freq/analyses/snv-frequencies)
**Module author:** Yuanchao Zhang ([@logstar](https://github.com/logstar))

Adapted from [fusion-frequencies](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/kgaonkar6/fusion_freq/analyses/fusion-frequencies)
**Module author:** Krutika Gaonkar ([@kgaonkar6](https://github.com/kgaonkar6))

Adapted by Eric Wafula ([@ewafula](https://github.com/ewafula)) 

### Purpose
Uses `consensus_wgs_plus_cnvkit_wxs.tsv.gz` consensus CNV calls and variant types (`amplification`, `deep deletion`, `gain`, `loss`, and `neutral`) to determine `Ensembl` gene-level mutation frequencies for each cancer type in an overall cohort dataset and in the independent primary/relapse cohort subsets of the data.

#### Additional annotation
Additional disease and gene annotations include `gene full names` `PMTL designations`, `OncoKB categories`, and `EFO and MONDO identifiers` integrated to the CNV frequencies table using the [long-format-table-utils analysis module)](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/long-format-table-utils).

For each `cancer_group_cohort` with `n_samples` >= 3, compute `Frequency_in_overall_dataset`, `Frequency_in_primary_tumors`, and `Frequency_in_relapse_tumors` as following:

- `Frequency_in_overall_dataset`:
  - For each unique variant/gene, count the number of patients (identified by `Kids_First_Participant_ID`) that have mutations at the variant/gene, and call this number `Total_mutations`.
  - Count the total number of patients in the `cancer_group_cohort`, and call this number `Patients_in_dataset`.
  - `Frequency_in_overall_dataset = Total_mutations / Patients_in_dataset`.

- `Frequency_in_primary_tumors`:
  - For each unique variant/gene, count the number of samples (identified by `Kids_First_Biospecimen_ID`) that have mutations at the variant/gene and are in the independent primary sample list, and call this number `Total_primary_tumors_mutated`.
  - Count the total number of samples in the `cancer_group_cohort` that are also in the independent primary sample list, and call this number `Primary_tumors_in_dataset`.
  - `Frequency_in_primary_tumors = Total_primary_tumors_mutated / Primary_tumors_in_dataset`.

- `Frequency_in_relapse_tumors`:
  - For each unique variant/gene, count the number of samples (identified by `Kids_First_Biospecimen_ID`) that have mutations at the variant/gene and are in the independent relapse sample list, and call this number `Total_relapse_tumors_mutated`.
  - Count the total number of samples in the `cancer_group_cohort` that are also in the independent relapse sample list, and call this number `Relapse_tumors_in_dataset`.
  - `Frequency_in_relapse_tumors = Total_relapse_tumors_mutated / Relapse_tumors_in_dataset`.


### Changes proposed by FNL for PedOT database

#### Renamed columns 
- `Gene_Ensembl_Id` to `targetFromSourceId`
- `EFO` to `diseaseFromSourceMappedId`
- `Total_alterations/Patients_in_dataset` to `Total_alterations_over_Patients_in_dataset`
- `Total_primary_tumors_altered/Primary_tumors_in_dataset` to `Total_primary_tumors_altered_over_Primary_tumors_in_dataset`
- `Total_relapse_tumors_altered/Relapse_tumors_in_dataset` to `Total_relapse_tumors_altered_over_Relapse_tumors_in_datase`


#### New columns
- `datatypeId` column with value for all rows set to `somatic_mutation`
- `chop_uuid` column with unique UUID for each row
- `datasourceId` column with value for all rows set to `chop_gene_level_cnv`



### Results

Results are generated using PediatricOpenTargets/OpenPedCan-analysis data release.

The merged CNV frequency table of all `cancer_group_cohort`s is output in TSV and JSONL formats.

- `gene-level-cnv-consensus-annotated-mut-freq.tsv.gz`
- `gene-level-cnv-consensus-annotated-mut-freq.jsonl.gz`

### Analysis scripts
NOTE: This module should be run on either `large memory server` or `an EC2 instance` and not locally on a laptop.

### `run-cnv-frequencies-analysis.sh`
This is a bash script wrapper for setting input file paths for the main analysis script, `01-cnv-frequencies.py`.All file paths set in this script relative to the module directory. Therefore, this script should always run as if it were being called from the directory it lives in, the module directory (OpenPedCan-analysis/analyses/cnv-frequencies).

Usage:
```bash
bash run-cnv-frequencies-analysis.sh

```

### `01-cnv-frequencies.py`
Python functions to create copy number variation (CNV) cancer type and study gene-level frequencies for OPenPedCan analyses modules

Usage:
```bash
python3 01-cnv-frequencies.py HISTOLOGY_FILE CNV_FILE  AC_PRIMARY_TUMORS AC_RELAPSE_TUMORS EC_PRIMARY_TUMORS EC_RELAPSE_TUMORS
```

Parameter Options:
```
positional arguments:
  HISTOLOGY_FILE  OPenPedCan histology file (histologies.tsv)
                  
  CNV_FILE        OPenPedCan CNV consensus file (consensus_wgs_plus_cnvkit_wxs.tsv.gz)
                  
  AC_PRIMARY_TUMORS  OPenPedCan all cohorts independent primary tumor samples file 
                  (independent-specimens.wgswxspanel.primary.prefer.wgs.tsv)
                  
  AC_RELAPSE_TUMORS  OPenPedCan all cohorts independent relapse tumor samples file 
                  (independent-specimens.wgswxspanel.relapse.prefer.wgs.tsv)
                  
  EC_PRIMARY_TUMORS  OPenPedCan each cohort independent primary tumor samples file 
                  (independent-specimens.wgswxspanel.primary.eachcohort.prefer.wgs.tsv)
                  
  EC_RELAPSE_TUMORS  OPenPedCan each cohort independent relapse tumor samples file 
                  (independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wgs.tsv)

optional arguments:
  -h, --help      show this help message and exit
  -v, --version   Print the current 01-cnv-frequencies.py version and exit
```

Input:
- `../../data/histologies.tsv`
- `../../data/consensus_wgs_plus_cnvkit_wxs.tsv.gz`
- `../../data/independent-specimens.wgswxspanel.primary.prefer.wgs.tsv`
- `../../data/independent-specimens.wgswxspanel.relapse.prefer.wgs.tsv`
- `../../data/independent-specimens.wgswxspanel.primary.eachcohort.prefer.wgs.tsv`
- `../../data/independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wgs.tsv`

Output:
- `results/gene-level-cnv-consensus-annotated-mut-freq.tsv.gz`
- `results/gene-level-cnv-consensus-annotated-mut-freq.jsonl.gz`

