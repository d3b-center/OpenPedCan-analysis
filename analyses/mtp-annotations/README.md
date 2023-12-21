# MTP Open Targets Diseases and Targets Annotations

## Module authors
David Hill and Eric Wafula

## Generating diseases and targets mapping files
This module transforms Open Targets Platform `Target` (core annotations for targets) and `Disease/Phenotype` (core annotations for diseases and phenotypes) tables into mapping files utilized in filtering MTP disgnated tables and OpenPedCan data release files for plotting API development.

## Module structure

1) The bash script,` run-mtp-annotations.sh` creates temporary directories in the file structure below to download `MTP Open Targets Platform` `targets` files to `scratch/mtp-json/targets/` and `disease` files to `scratch/mtp-json/diseases/`. The bash script is also converts downloaded JSON files to CSV format and executes the annotions mapping R script, `01-mtp-annotations.R`. 

2) The R script,` 01-mtp-annotations.R` created the required module outputs, `mtp-targets-mapping.tsv` and `mtp-diseases-mapping.tsv` written to the module `results/` directory.


```
├── OpenPedCan-analysis/
    ├── scratch/
    │   ├── mtp-json/
    │   │  ├── targets/*.json
    │   │  └── diseases/*.json
    │   └── mtp-csv/*.csv
    │     ├── targets/*.cvs
    │     └── diseases/*.cvs
    └── analyses/
        └── mtp-annotations/
            ├── README.md
            ├── 01-mtp-annotations.R
            ├── run-mtp-annotations.sh
            └── results/
                ├── mtp-targets-mapping.tsv
                └── mtp-diseases-mapping.tsv
```
