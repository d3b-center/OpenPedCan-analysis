## Differential Expression of RNA-seq matrices


This module takes as input histologies and the RNA-Seq expression matrices data, and performs differential expression analysis for all combinations of GTEx subgroup (normal) and cancer histology type (tumor).



## Expected Input

Data files must be downloaded using the below script
```
download-data.sh
```



## Scripts 

` run-generate-Hist-GTEx-indices-file.R` - This script creates a subset of `histologies.tsv` and `gene-counts-rsem-expected_count-collapsed.rds` file. The script shortlists the cancer_group and cohort combinations that 3 or more participants with clinical data and prepares the histology and gene counts data subsets that can be used for downstream differential expression analysis by the other R script in this module. This script generates 5 output files as listed below:
1) `Input_Data/histologies_subset.tsv` - Histology subset for cancer groups with sufficient clinical data from participants
2) `Input_Data/countData_subset.rds` -   Gene counts data subset
3) `Input_Data/GTEx_Index_limit.txt` - maximum count of GTEx tissues that have sufficient clinical data
4) `Input_Data/Hist_Index_limit.txt` - maximum count of cancer histology
5) `Input_Data/filelist_expected.txt` - a list of all filenames as combination of cancer_group and cohort combinations expected if the module runs successfully
6) `indices.txt` - pairs of indices of cancer histology and GTEx tissue, to be used by the slurm set up for parallelization.

` run-generate-Hist-GTEx-indices-file.sh` - This script runs the ` run-generate-Hist-GTEx-indices-file.R` script.

`run-deseq-analysis.R` - This is the main script that reads the downloaded data files, performs differential expression analysis for each pair of GTEx tissue and cancer histology as found in the subsets created by the `run-generate_Hist_GTEx_indices_file.R` script, and prints out json and tsv files per set of cancer histology and GTEx tissue.

` run-tumor-normal-differential-expression.sh` - This script loads the above described main script `run-deseq-analysis.R` on slurm for parallelization. Therefore, each of the two R scripts and two bash scripts must be loaded on to the cluster for execution, along with the required data files including `gene-expression-rsem-tpm-collapsed.rds`, `efo-mondo-map.tsv`, `uberon-map-gtex-subgroup.tsv`, `ensg-hugo-rmtl-mapping.tsv`, ` independent-specimens.rnaseq.primary.tsv`, ` independent-specimens.rnaseq.primary.eachcohort.tsv`  as well as `histologies.tsv`, and `gene-counts-rsem-expected_count-collapsed.rds`.



## Steps
1) Load the data files, and script files on the cluster with a directory set up similar to the repository
2) Set working directory to module level
3) Create a new directory to capture messages from Slurm execution with the following command: `mkdir Logs_DESeq2_v12` or other suitable name. Make sure it matches the name specified in the below scripts.
3) Verify all the input files and paths are correct, and output filenames and path are as expected.
4) Run `run-generate-Hist-GTEx-indices-file.sh`
5) Run `run-tumor-normal-differential-expression.sh` with sbatch command (This step may take a few hours)

## Note
- Confirm beforehand 
	Input filename for indices is correct in the `run-tumor-normal-differential-expression.sh` script
	Number of cores specified in shell script is greater than number of pairs of comparison expected
	Memory per CPU specified in shell script is optimal considering the largest sample set
	Logs directory exists
- When the job is initiated - 
  Capture the job id
  Use below commands to monitor the process
    `squeue -u <username>`
	  `ls -l results/*.tsv | wc -l`
	  `ls -l results/*.jsonl | wc -l`


## Results
When running on a high performance cluster, the module will create a `results` directory which holds all the results `.tsv` and `.jsonl` files.
Final step is to concatenate all the `.tsv` files into one big file with a single table for all the differential expression comparisons; and also concatenating all the `.jsonl` files into one big file. This can be done with the below code via command line on the cluster.

`nohup cat results/Results*.jsonl > gene-counts-rsem-expected_count-collapsed-deseq.jsonl &`

`nohup awk '(NR == 1) || (FNR > 1)' results/Results*.tsv > gene-counts-rsem-expected_count-collapsed-deseq.tsv &`


Run a QC script to verify if all expected comparisons are found in the final results. If not, which ones are missing. Also print a few deseq results into a file for spot checking.

`nohup bash run-qc-tumor-normal-differential-expression.sh &`


Finally, run command to compress TSV and JSONL results. Below command will replace existing file with new compressed filename
`gzip -f filename`

If you need to keep the original file, use option as below
`gzip -k filename`

## Visualization
For visualization purposes, we also create an .RDS version of the final results. This module contains a script `convert_tsv_to_rds.R` to do that. Ensure that the .TSV file with the combined results is named deseq_all_comparisons.tsv. Or, if a different filename is used, edit the `slurm_tsv_to_rds.sh` script to reflect that. And then run the below command with Slurm (this step may take a few hours)

`Sbatch slurm_tsv_to_rds.sh`


## Dockerfile

Too run the module with Docker, create similar directory and files set up, and then build Dockerfile.
To build Dockerfile, use below:
`
docker build -t deseq2_cavatica .
`

If you plan to use the module with the Dockerfile to build an interactive app on CAVATICA, also push the docker image to your docker hub.

To run Docker image for executing the script to create histology and counts subset, use below:
`
docker run --volume $PWD:/analysis deseq2_cavatica bash -c "cd /analysis && Rscript --vanilla ./analysis/run-generate-Hist-GTEx-indices-file.R  --hist_file ./data/histologies.tsv --counts_file ./data/gene-counts-rsem-expected_count-collapsed.rds --ind_allcohorts ./data/independent-specimens.rnaseq.primary.tsv --ind_eachcohort ./data/independent-specimens.rnaseq.primary.eachcohort.tsv --outdir Input_Data"
`

To run the Docker image for executing the main script for DESeq comparisons, use below:
`
docker run --volume $PWD:/analysis deseq2_cavatica bash -c "cd /analysis && Rscript --vanilla ./analysis/run-deseq-analysis.R --hist_file ./data/histologies.tsv --counts_file ./data/gene-counts-rsem-expected_count-collapsed.rds --tpm_file ./data/gene-expression-rsem-tpm-collapsed.rds --ensg_hugo_file ./data/ensg-hugo-pmtl-mapping.tsv --efo_mondo_file ./data/efo-mondo-map.tsv --gtex_subgroup_uberon ./data/uberon-map-gtex-subgroup.tsv --outdir results --ind_allcohorts ./data/independent-specimens.rnaseq.primary.tsv --ind_eachcohort ./data/independent-specimens.rnaseq.primary.eachcohort.tsv --HIST_i 1 --GTEX_i 1"
`
Note: In the above command, `--HIST_i` and `-–GTEX_i` are initialized as 1, since the process is CPU heavy, and not recommended to run on non-HPC servers. Initializing those index values small, is meant only for testing purposes.

## CAVATICA
While the module requires an HPC environment for implementation, to enable non-HPC implementation this module is also wrapped into a [CAVATICA](https://d3b.center/our-research/cavatica/) application. To run on CAVATICA, the user must download scripts and publish an application You must maintain the same file structure while creating and publishing the application.

Following command can be used to publish an application on CAVATICA:
`sbpack cavatica user/projectname/workflowname workflows/run_deseq_analysis_wf.cwl`
Refer to this link for instructions on setting up [sbpack](https://docs.cavatica.org/docs/maintaining-and-versioning-cwl-on-external-tool-repositories).
The data files required for running the application are also publicly available [here](https://cavatica.sbgenomics.com/u/cavatica/opentarget). 


