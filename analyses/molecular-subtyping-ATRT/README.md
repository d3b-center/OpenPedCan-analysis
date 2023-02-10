# Molecular Subtyping ATRT
Module authors: Zhuangzhuang Geng and Jo Lynne Rokita

*Note: the previous files/scripts can be find in Archive folder*

## Usage

To run all of the Rscripts in this module from the command line sequentially, use:

```
bash run-molecular-subtyping-ATRT.sh
```

`run-molecular-subtyping-ATRT.sh` is designed to be run as if it was called from this module directory even when called from outside of this directory.

## Folder content

This folder contains scripts tasked to molecularly subtype ATRT samples in the PBTA dataset.

`00-ATRT_subtyping.R` selects samples from `histologies-base.tsv` and subtypes all PBTA and/or DGD tumor biospecimens into three subtypes, (`ATRT, MYC`, `ATRT, SHH` and `ATRT, TYR`).

* Filter the samples with `cns_methylation_subclass_score >=0.8` and `cns_methylation_subclass` is one of the three ATRT subtypes ->
  * `ATRT, MYC`
  * `ATRT, SHH`
  * `ATRT, TYR`
* Filter the samples with `cns_methylation_subclass_score >=0.8` and `cns_methylation_subclass` is not one of the three ATRT subtypes -> `ATRT, To be clasified`
* If methylation does not exist for any ATRT samples -> `ATRT, To be clasified`

Final results is a table with `sample_id`, `Kids_First_Biospecimen_ID_meth`, `Kids_First_Biospecimen_ID_DNA`, `Kids_First_Biospecimen_ID_RNA`, and `molecular_subtype`, and saved as `ATRT-molecular-subtypes.tsv`