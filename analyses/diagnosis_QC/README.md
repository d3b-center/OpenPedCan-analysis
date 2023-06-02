## Create list of cancer group/path dx discrepancies based on high-confidence methyl subtypes 

This module is designed to create a list of samples whose pathology diagnosis and/or finalized molecular subtype & cancer group do not agree with the corresponding high confidence (`dkfz_v12_methylation_subclass_score >= 0.8 methyl score`) methylation subtype calls.

### Input

* `histologies.tsv`: v12 histologies file
* `mnp_v12.5_annotation_with_OPC_subtype - Sheet1.tsv`: can be used to convert dkfz_v12_methylation_subclass to the molecular subtype used in OpenPedCan histology file. 

### Script

`01_diagnosis_QC.Rmd` is taking `histology_base.tsv` and `mnp_v12.5_annotation_with_OPC_subtype - Sheet1.tsv` as input. First, the broad histology is added to corresponding methylation molecular subtypes. From histology file, samples with high methylation subclass score (>= 0.8) and unmatched pathology diagnosis and methylation subtype are selected. The script generate two outputs: 

* `unmatched_sample_all.tsv` contains the sample with different broad histology and methylation broad histology. 

* `missing_subtype.tsv` contains the samples without neither molecular_subtypes nor molecular_subtype_methyl.



