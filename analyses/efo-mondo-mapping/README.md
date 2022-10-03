# EFO, MONDO, and NCIT mapping

## Introduction and Purpose

The Experimental Factor Ontology (EFO) is a resource that provides systematic description of experimental variables including cancer groups available in [European Bioinformatics Institute](https://www.ebi.ac.uk/) databases and some other external projects. 
The scope of EFO is to support the annotation, analysis and visualization of data handled by many groups at the EBI and as the core ontology for [OpenTargets](https://www.opentargets.org/).

The Mondo Disease Ontology ([MONDO](https://obofoundry.org/ontology/mondo.html)) is another independent resource aiming to harmonize disease definitions. 

[NCI Thesaurus (NCIt)](https://ncithesaurus.nci.nih.gov/ncitbrowser/pages/home.jsf?version=22.04d) provides reference terminology for many NCI and other systems. NCIt includes rigorous human and machine readable definitions of many thousands of distinct types of neoplasm, organized in logic based parent-child hierarchies.

The purpose of maintaining `efo-mondo-map.tsv` is to map each cancer group found in the `histologies.tsv` to its appropriate EFO,  MONDO, and NCIT codes.

## Format

The EFO codes may have prefix “EFO_”, “MONDO_” or “Orphanet_”, the MONDO codes have a prefix “MONDO_”; each followed by seven digits; and NCIT codes have a prefix "NCIT_".

## Automated OLS search
The module enables an automated search to retrieve EFO, MONDO, and NCIT codes for all `cancer_group` found in the current data release `efo-mondo-map-prefill.tsv` file. Executing the script `run_search_and_qc.sh` creates `.tsv` files under `results` directory in the module which are then merged into a single file describing the cancer_group, old EFO and MONDO codes as found in the `efo-mondo-map-prefill.tsv`, EFO, MONDO and NCIT codes retrieved by the automated search, and T/F flag columns describing if the old and new codes match. If needed, the script can also include other OLS ontology types such as HP, UBERON, et cetera.


The `results/efo-mondo-map-prefill-auto.tsv` file must be manually reviewed for each `cancer_group` to curate acceptable EFO, MONDO, and NCIT codes that must be included in the `efo-mondo-mapping.tsv` file. The T/F flag columns show whether the codes retrieved match with the existing codes, and are useful for such curation.


## File QC
To make sure all the cancer_group with n>=3 in the histologies file are included in the efo-mondo-map.tsv file, a QC Rmd script is included in the repo. This notebook can be run with the command bash run_qc.sh This QC step should be done for all new histologies file release before generating SNV, CNV and fusion frequencies tables.


## Run module
Both tasks as mentioned above are performed by running the `run_search_and_qc.sh` script as below.

`bash run_search_and_qc.sh`


## Note
As more cancer groups or subtypes are added to existing histologies dataset and/or in case of any ambiguity, these codes will be revised with a combination of manual curation and automated search.
