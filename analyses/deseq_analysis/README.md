## Differential Expression of RNA-seq matrices


This module takes as input histologies and the RNA-Seq expression matrices data, and performs differential expression analysis for all combinations of GTEx subgroup and cancer histology type.



## Expected Input

Data files must be downloaded using the below script
```
download-data.sh
```



## Scripts 

`run-Generate_Hist_GTEx_indices_file.R` - This script creates a subset of `histologies.tsv` and `gene-counts-rsem-expected_count-collapsed.rds` file. The script shortlists the cancer_group and cohort combinations that 3 or more participants with clinical data and prepares the histology and gene counts data subsets that can be used for downstream differential expression analysis by the other R script in this module. This script generates 5 output files as listed below:
1) `Input_Data/histologies_subset.tsv` - Histology subset for cancer groups with sufficient clinical data from participants
2) `Input_Data/countData_subset.rds` -   Gene counts data subset
3) `Input_Data/GTEx_Index_limit.txt` - maximum count of GTEx tissues that have sufficient clinical data
4) `Input_Data/Hist_Index_limit.txt` - maximum count of cancer histology
5) `indices.txt` - pairs of indices of cancer histology and GTEx tissue, to be used by the slurm set up for parallelization.

`run_Generate_Hist_GTEx_indices_file.sh` - This script runs the `run-Generate_Hist_GTEx_indices_file.R` script.

`run-deseq-analysis.R` - This is the main script that reads the downloaded data files, performs differential expression analysis for each pair of GTEx tissue and cancer histology as found in the subsets created by the `run-Generate_Hist_GTEx_indices_file.R` script, and prints out json and tsv files per set of cancer histology and GTEx tissue.

`run_deseq_slurm.sh` - This script loads the above described main script on slurm for parallelization. Therefore, each of the two R scripts and two bash scripts must be loaded on to the cluster for execution, along with the required data files including `gene-expression-rsem-tpm-collapsed.rds`, `efo-mondo-map.tsv`, `uberon-map-gtex-subgroup.tsv`, `ensg-hugo-rmtl-mapping.tsv`, as well as `histologies.tsv`, and `gene-counts-rsem-expected_count-collapsed.rds`.



## Steps
1) Load the data files, and script files on the cluster with a directory set up similar to the repository
2) Set working directory to /deseq_analysis
3) Create a new directory to capture messages from Slurm execution with the following command: `mkdir Logs_DESeq2`
4) Run `run_Generate_Hist_GTEx_indices_file.sh`
5) Run `run_deseq_slurm.sh` with sbatch command


## Results
When running on a high performance cluster, the module will create a `results` directory which holds all the results `.tsv` and `.jsonl` files.
Final step is to concatenate all the `.tsv` files into one big file with a single table for all the differential expression comparisons; and also concatenating all the `.jsonl` files into one big file. This can be done with the below code via command line on the cluster.

`cat results/Results*.jsonl > results/deseq_all_comparisons.jsonl`

`awk '(NR == 1) || (FNR > 1)' results/Results*.tsv > results/deseq_all_comparisons.tsv`



Dockerfile

To build Dockerfile, use below:
`
docker build -t deseq2_cavatica .
`

To run Docker image for executing the script to create histology and counts subset, use below:
`
docker run --volume $PWD:/analysis deseq2_cavatica bash -c "cd /analysis && Rscript --vanilla ./analysis/run-Generate_Hist_GTEx_indices_file.R  --hist_file ./data/histologies.tsv --counts_file ./data/gene-counts-rsem-expected_count-collapsed.rds --outdir Input_Data"
`

