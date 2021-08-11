## Differential Expression of RNA-seq matrices


This module takes histologies data and the corresponding gene counts and tpm data, and performs differential expression analysis for all combinations of GTEx subgroup and histology type.



## Expected Input

Data files must be downloaded using the below script
```
download-data.sh
```




## Scripts 

`run-DESeq-analysis.R` - This is the main script that reads the downloaded data files and prints out json and tsv files.

`run_deseq.sh` - This script sets the path for the output tables and calls the above R script.

`process_test_input.R` - This script will create a subset of histologies.tsv. The script searches the cancer_group and cohort combinations that have more than 5 patients with clinical data, and requires the user to specify the desired cancer_group and cohort to use for the new subset creation.

`run_process_test_input.sh` - This script runs the create_test_input.R. This works well with v7 data since the selected cancer_group and cohort to subset for, are reviewed to have more than 5 patients with clinical data. This script will use the newly created subset and process it by running run_DESeq_analysis.R, and create test result table.




## Steps
1) Set working directory to /deseq_analysis
2) For testing with v7, run the script run_create_test_input.sh
3) Review the path and file created as test data, and the subsequent result tables created
4) In order to run the module for the entire set of data, run run_deseq.sh


