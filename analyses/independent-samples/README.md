# Independent Samples

## Module authors
Komal Rathi, Run Jin, Yuanchao Zhang, Eric Wafula, Sangeeta Shukla, Jo Lynne Rokita

## Generating sample lists

There are two modes for generating independent sample lists:

- _Release mode_: Pre-release independent sample lists are generated using the `histologies-base.tsv` file, and these lists are used to run modules specific to release (eg: `fusion_filtering`).
`OPENPBTA_BASE_SUBTYPING=1 bash run-independent-samples.sh`

- _Analysis mode_: Independent sample lists are generated per cohort and per cohort and cancer group, which requires `histolologies.tsv`.
`OPENPBTA_BASE_SUBTYPING=0 bash run-independent-samples.sh`

## Module structure

* `01-generate-independent-specimens-wgs-only.R`: Generate tables of WGS-only independent specimens where no two specimens are chosen from the same individual.
* `01-generate-independent-specimens-wgs-preferred.R`: Generate tables of WGS-preferred independent specimens where no two specimens are chosen from the same individual. 
* `01-generate-independent-specimens-wxs-preferred.R`: Generate tables of WXS-preferred independent specimens where no two specimens are chosen from the same individual.
* `02-generate-independent-rnaseq.R`: Generate tables of independent rna-seq specimens.
* `03-qc-independent-samples.Rmd`: Markdown to tabulate number of biospecimen ids for same participant ids from each output file.
* `04-generate-independent-specimens-rnaseq-pre-release.R`: Generate tables of RNA-Seq-only independent specimens where no two specimens are chosen from the same individual. 
* `05-generate-independent-specimens-methyl.R`: Generate tables of Methylation-DNA independent specimens.
(Note: these tables will only be used for the `fusion_filtering` module runs pre-release).

```
.
├── 00-repeated-samples.Rmd
├── 00-repeated-samples.nb.html
├── 01-generate-independent-specimens-wgs-only.R
├── 01-generate-independent-specimens-wgs-preferred.R
├── 01-generate-independent-specimens-wxs-preferred.R
├── 02-generate-independent-rnaseq.R
├── 03-qc-independent-samples.Rmd
├── 03-qc-independent-samples.nb.html
├── 04-generate-independent-specimens-rnaseq-pre-release.R
├── 05-generate-independent-specimens-methyl.R
├── README.md
├── results
│   ├── independent-specimens.methyl.relapse.tsv
│   ├── independent-specimens.methyl.primary.tsv
│   ├── independent-specimens.methyl.relapse.eachcohort.tsv
│   ├── independent-specimens.methyl.primary.eachcohort.tsv
│   ├── independent-specimens.methyl.primary-plus.eachcohort.tsv
│   ├── independent-specimens.methyl.primary-plus.tsv
│   ├── independent-specimens.rnaseqpanel.primary-plus.eachcohort.tsv
│   ├── independent-specimens.rnaseqpanel.primary-plus.tsv
│   ├── independent-specimens.rnaseqpanel.primary-plus.pre-release.tsv
│   ├── independent-specimens.rnaseqpanel.primary.eachcohort.tsv
│   ├── independent-specimens.rnaseqpanel.primary.tsv
│   ├── independent-specimens.rnaseqpanel.primary.pre-release.tsv
│   ├── independent-specimens.rnaseqpanel.relapse.eachcohort.tsv
│   ├── independent-specimens.rnaseqpanel.relapse.tsv
│   ├── independent-specimens.rnaseqpanel.relapse.pre-release.tsv
│   ├── independent-specimens.wgs.primary-plus.eachcohort.tsv
│   ├── independent-specimens.wgs.primary-plus.tsv
│   ├── independent-specimens.wgs.primary.eachcohort.tsv
│   ├── independent-specimens.wgs.primary.tsv
│   ├── independent-specimens.wgs.relapse.eachcohort.tsv
│   ├── independent-specimens.wgs.relapse.tsv
│   ├── independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wxs.tsv
│   ├── independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wgs.tsv
│   ├── independent-specimens.wgswxspanel.primary-plus.prefer.wxs.tsv
│   ├── independent-specimens.wgswxspanel.primary-plus.prefer.wgs.tsv
│   ├── independent-specimens.wgswxspanel.primary.eachcohort.prefer.wxs.tsv
│   ├── independent-specimens.wgswxspanel.primary.eachcohort.prefer.wgs.tsv
│   ├── independent-specimens.wgswxspanel.primary.prefer.wxs.tsv
│   ├── independent-specimens.wgswxspanel.primary.prefer.wgs.tsv
│   ├── independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wxs.tsv
│   ├── independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wgs.tsv
│   ├── independent-specimens.wgswxspanel.relapse.prefer.wxs.tsv
│   └── independent-specimens.wgswxspanel.relapse.prefer.wgs.tsv
├── run-independent-samples.sh
└── util
    ├── independent-dna-samples.R
    └── independent_rna_samples.R
```

## Summary

Many analyses that involve mutation frequencies or co-occurence require that all samples be independent. However, the `OpenPedCan` data set includes many cases where multiple biospecimens were taken from a single participant. This analysis creates lists of samples such that there are no cases where more than one biospecimen is included from each participant.

As different analyses may require different sets of data, we generate a few different sets, stored in the `results` subdirectory. We run the analyses based on different `independent_level`, either `each-cohort` or `all-cohorts`. For `each-cohort` analysis, we generate a list of independent samples using `Kids_First_Participant_ID` unique within each `cohort + cancer_group` combination. In this case, same `Kids_First_Participant_ID` across different cohorts is treated as `independent`. For `all-cohorts` analysis, we generate a list of independent samples using `Kids_First_Participant_ID` regardless of `cohort` or `cancer_group` and only one occurence of `Kids_First_Participant_ID` is chosen from the entire dataset.

## Outputs

### WGS-only lists

These lists contain only WGS samples:

1. **All-cohorts specific lists**

* Primary specimens only with whole genome sequence (WGS):  
`independent-specimens.wgs.primary.tsv`
* Relapse specimens with WGS:  
`independent-specimens.wgs.relapse.tsv`
* Primary and relapse specimens with WGS:  
`independent-specimens.wgs.primary-plus.tsv`

2. **Each-cohort specific lists**

* Primary specimens only with whole genome sequence (WGS):  
`independent-specimens.wgs.primary.eachcohort.tsv`
* Relapse specimens with WGS:  
`independent-specimens.wgs.relapse.eachcohort.tsv`
* Primary and relapse specimens with WGS:  
`independent-specimens.wgs.primary-plus.eachcohort.tsv`

### WGS-preferred lists

For WGS-preferred lists, when a `Kids_First_Participant_ID` is associated with multiple `experimental_strategy` values i.e. `WGS`, `WXS` or `Targeted Sequencing`, priority is given to a single randomly chosen `WGS` biospecimen first, followed by a single randomly chosen `WXS` and lastly a single randomly chosen `Targeted Sequencing` sample.

After randomizing the histology file subset to tumor samples:

```
tumor_samples <- histology_df %>%
  dplyr::filter(sample_type == "Tumor", 
                composition != "Derived Cell Line", 
                experimental_strategy %in% c("WGS", "WXS", "Targeted Sequencing"),
                !grepl("Metastatic secondary tumors", pathology_diagnosis, ignore.case = FALSE, perl = FALSE, 
                        fixed = FALSE, useBytes = FALSE))
```

For WGS-preferred lists, we first subset the **tumor samples** to `WGS` samples only, pass the subsetted samples to the `independent-samples.R` function to generate a `WGS-specific` list. This list only contains a single occurence of `Kids_First_Participant_ID` associated to the `experimental_strategy = WGS`. Next, we subset the **tumor samples** to `WXS` and `Targeted Sequencing` samples only, pass the subsetted samples to the `independent-samples.R` function to generate a `WXS/Panel specific` list. This list only contains a single occurence of `Kids_First_Participant_ID` associated to either `experimental_strategy = WXS` or `experimental_strategy = Targeted Sequencing`. Then we merge the two lists (keeping `WGS` list first and `WXS/Panel` as second) and take a `dplyr::distinct` to only get the first occurence of `Kids_First_Participant_ID`. Because we keep the `WGS` specific list first when calling `dplyr::distinct`, the `WGS` associated biospecimens will be preferred over other biospecimens for multiple occurrences of `Kids_First_Participant_ID`.

1. **All-cohorts specific lists**

* Primary specimens only with either WGS or whole exome sequence (WXS) or Panel:  
`independent-specimens.wgswxspanel.primary.prefer.wgs.tsv`
* Relapse specimens only with either WGS or whole exome sequence (WXS) or Panel:  
`independent-specimens.wgswxspanel.relapse.prefer.wgs.tsv`
* Primary and relapse specimens with WGS or WXS or Panel:  
`independent-specimens.wgswxspanel.primary-plus.prefer.wgs.tsv`

2. **Each-cohort specific lists**

* Primary specimens only with either WGS or whole exome sequence (WXS) or Panel:  
`independent-specimens.wgswxspanel.primary.eachcohort.prefer.wgs.tsv`
* Relapse specimens only with either WGS or whole exome sequence (WXS) or Panel:  
`independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wgs.tsv`
* Primary and relapse specimens with WGS or WXS or Panel:  
`independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wgs.tsv`

### WXS-preferred lists

Additionally, similar independent lists that consist of all DNA `experimental_strategy` were generated prioriting `WXS` specimens when both WXS and WGS samples were available - this independent list will be used for analyzing SNV datasets since WXS gives higher coverage for coding regions and hence, better chance of detecting SNV.

For WXS-preferred lists, when a `Kids_First_Participant_ID` is associated with multiple `experimental_strategy` values i.e. `WGS`, `WXS` or `Targeted Sequencing`, priority is given to a single randomly chosen `WXS` biospecimen first, followed by a single randomly chosen `WGS` and lastly a single randomly chosen `Targeted Sequencing` sample.

After randomizing the histology file subset to tumor samples:

```
tumor_samples <- histology_df %>%
  dplyr::filter(sample_type == "Tumor", 
                composition != "Derived Cell Line", 
                experimental_strategy %in% c("WGS", "WXS", "Targeted Sequencing"),
                !grepl("Metastatic secondary tumors", pathology_diagnosis, ignore.case = FALSE, perl = FALSE, 
                        fixed = FALSE, useBytes = FALSE))
```

For WXS-preferred lists, we first subset the **tumor samples** to `WXS` samples only, pass the subsetted samples to the `independent-samples.R` function to generate a `WXS-specific` list. This list only contains a single occurence of `Kids_First_Participant_ID` associated to the `experimental_strategy = WXS`. Next, we subset the **tumor samples** to `WGS` and `Targeted Sequencing` samples only, pass the subsetted samples to the `independent-samples.R` function to generate a `WGS/Panel specific` list. This list only contains a single occurence of `Kids_First_Participant_ID` associated to either `experimental_strategy = WGS` or `experimental_strategy = Targeted Sequencing`. Then we merge the two lists (keeping `WXS` list first and `WGS/Panel` as second) and take a `dplyr::distinct` to only get the first occurence of `Kids_First_Participant_ID`. Because we keep the `WXS` specific list first when calling `dplyr::distinct`, the `WXS` associated biospecimens will be preferred over other biospecimens for multiple occurrences of `Kids_First_Participant_ID`.

1. **All-cohorts specific lists**

* Primary specimens only with either whole exome sequence (WXS) or WGS or Panel:  
`independent-specimens.wgswxspanel.primary.prefer.wxs.tsv`
* Relapse specimens only with either whole exome sequence (WXS) or WGS or Panel:  
`independent-specimens.wgswxspanel.relapse.prefer.wxs.tsv`
* Primary and relapse specimens with WXS or WGS or Panel:  
`independent-specimens.wgswxspanel.primary-plus.prefer.wxs.tsv`

2. **Each-cohort specific lists**

* Primary specimens only with either whole exome sequence (WXS) or WGS or Panel:  
`independent-specimens.wgswxspanel.primary.eachcohort.prefer.wxs.tsv`
* Relapse specimens only with either whole exome sequence (WXS) or WGS or Panel:  
`independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wxs.tsv`
* Primary and relapse specimens with WXS or WGS or Panel:  
`independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wxs.tsv`

### RNA-sequencing lists

Simiarly, for independent RNA samples, we also run with either `all-cohorts` or `each-cohort`.
When run with `each-cohort`, independent DNA samples ran with `each-cohort` was used as starting point (see code for details) and when run with `all-cohorts`, independent DNA samples ran with `all-cohorts` was used as starting point.

When multiple RNA-Seq samples exist per participant, the script matches the independent whole genome or whole exome sample_ids to gather matched RNA-Seq sample. If participant has only RNA-Seq sample then a primary (and relapse if applicable) sample is randomly selected per participant per cancer group per cohort. 

1. **All-cohorts specific lists**

* Primary RNA-Seq specimens matching WGS/WXS/Panel independent sample_ids plus only-RNA-Seq 
`independent-specimens.rnaseqpanel.primary-plus.tsv` and `independent-specimens.rnaseqpanel.primary-plus.pre-release.tsv` 
* Relapse RNA-Seq specimens matching WGS/WXS/Panel independent sample_ids plus only-RNA-Seq 
`independent-specimens.rnaseqpanel.primary.tsv` and `independent-specimens.rnaseqpanel.primary.pre-release.tsv`
* Primary and Relapse RNA-Seq specimens matching WGS/WXS/Panel independent sample_ids plus only-RNA-Seq 
`independent-specimens.rnaseqpanel.relapse.tsv` and `independent-specimens.rnaseqpanel.relapse.pre-release.tsv`

Note: `*pre-release.tsv` files are generated pre-release, require `histologies-base.tsv`, and are only being used to run `fusion_filtering`.

2. **Each-cohort specific lists**

* Primary RNA-Seq specimens matching WGS/WXS/Panel independent sample_ids plus only-RNA-Seq 
`independent-specimens.rnaseqpanel.primary-plus.eachcohort.tsv`
* Relapse RNA-Seq specimens matching WGS/WXS/Panel independent sample_ids plus only-RNA-Seq 
`independent-specimens.rnaseqpanel.primary.eachcohort.tsv`
* Primary and Relapse RNA-Seq specimens matching WGS/WXS/Panel independent sample_ids plus only-RNA-Seq 
`independent-specimens.rnaseqpanel.relapse.eachcohort.tsv`

### Methylation lists

These lists contain independent methylation array samples:

* Primary specimens:  
`independent-specimens.methyl.primary.tsv`
`independent-specimens.methyl.primary.eachcohort.tsv`
* Relapse specimens:  
`independent-specimens.methyl.relapse.tsv`
`independent-specimens.methyl.relapse.eachcohort.tsv`
* Primary and relapse:  
`independent-specimens.methyl.primary-plus.tsv`
`independent-specimens.methyl.primary-plus.eachcohort.tsv`

## Generating sample lists

To generate the independent sample lists and associated analysis of redundancies in the overall data set, run the following script from the project root directory:

```sh
bash analyses/independent-samples/run-independent-samples.sh
```

## Additional info:
- When presented with more than one specimen from a given individual with a specific cancer group and cohort, the script selects the first occurrence of the individual so as to include only one specimen, with preference for primary tumors and whole genome sequences where available.
- The input histology file is randomized using a seed before using as input in order to avoid any selection bias. Using a seed allows for reproducibility of the randomized histology file.
- There is also a preference for the earliest collected samples, but as this data is not currently available, that code is currently deleted.

