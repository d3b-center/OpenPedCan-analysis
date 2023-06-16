---
name: Bix Ops kids-first/D3B dataset harmonization ticket
about: Use this issue template to create a kids-first/D3B datasets harmonization ticket
title: 'Bix Ops harmonization request , [study name]'
labels: bix-ops, harmonization
assignees: zhangb1
---

<!--Hi there! Please take a moment to fill out the template below.-->


## This section is required for PM/ADAPT team


### [Required] For what study (study_id) is this request?


### [Required] Basic study information 
- [ ] Is this an OT or Kids First study:
- [ ] If KF, PI name and fiscal year:
- [ ] Study short name:

**NOTE**: Study short name is required for D3B study, but optional for Kids First X01; Fiscal year is required for Kids First X01, but optional for D3B study. Those information will be used for project naming in Cavatica.


### [Required] What workflow needs to be done?
For reference: https://www.notion.so/d3b/workflow-type-365a604413534b2b9d93c969557d60a2 

- [ ] alignment
- [ ] gatk-hc-gvcf
- [ ] family-vcf-genotyping
- [ ] cohort-vcf-genotyping
- [ ] single-vcf-genotyping
- [ ] somatic-analysis
- [ ] rnaseq-analysis
- [ ] only delivery of the source data
- [ ] rnaseq toolkit run ( this would be D3b toolkit modules like collapse RSEM files , merge RSEM files , merge fusion calls )
- [ ] dnaseq toolkit run ( this would be D3b toolkit modules like consensus CNV analysis, merge consensus maf files )


### [Required] Requested sample manifest.
Please provide a description selection criteria for the samples need to be processed. E.g. "the entire study" or "all visible tumors". Along with a requested sample manifest in the format of tab delimited file with columns of `biospecimen_id`, `experiment_strategy`, `source_text_tissue_type` and `genomics_file_id`. Please attach the manifest directly to this ticket or post a downloadable link if manifest is on DataTracker. 


### [Required] Billing group for this study? 
If there's no billing group setup for this study or project yet, please follow the [D3b Billing Workflow guidelines](https://www.notion.so/d3b/D3b-Billing-Workflow-a60afac8f4ce4e6ea0ec416c0adc749b) and submit your request at [D3b Billing Group Creation board](https://www.notion.so/d3b/259a780a53da4f3e9c9e6be966e02220?v=c1a9a2c342264cf59508e5fba90cd663)


### [Optional] List bucket names for source files.


### [Optional] What is the priority for the analysis? (Low, Medium, High)


### [Optional] How long do you think this work will take?


### [Optional] Who will complete this work?


---


## This section is ONLY REQUIRED for Bixops manager/operations


### [Required] Provide Cavatica project link.


### [Required] Provide details for analysis workflow(s).
