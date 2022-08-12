# Fusion Summary

This module generates summary files for fusions of interest present in biospecimens taken from:
  
  1. Ependymoma tumors
2. Embryonal tumors not from ATRT or MB
3. CNS Ewing Sarcomas
4. LGAT tumors

To generate the tables run:
  
  ```
bash run-new-analysis.sh
```

## General Use

The program generates files that contain information about the presence or absence of specific fusions or genes participating in fusions.
These can be potentially used for further downstream molecular subtyping analyses.

### Reference

https://github.com/AlexsLemonade/OpenPBTA-analysis/issues/398
https://github.com/AlexsLemonade/OpenPBTA-analysis/issues/623
https://github.com/AlexsLemonade/OpenPBTA-analysis/issues/825
https://github.com/AlexsLemonade/OpenPBTA-analysis/issues/808

### Input files
```
# reference file
genelistreference.txt

# data file
fusion-putative-oncogenic.tsv
fusion-arriba.tsv.gz
fusion-starfusion.tsv.gz
fusion-dgd.tsv.gz
```

### Output files
```
fusion_summary_ependymoma_foi.tsv
fusion_summary_embryonal_foi.tsv
fusion_summary_ewings_foi.tsv
fusion_summary_lgat_foi.tsv
```
