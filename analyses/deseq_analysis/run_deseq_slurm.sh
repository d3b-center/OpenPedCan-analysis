#!/usr/bin/bash
#SBATCH --job-name=Run_Deseq2_auto              # Job Name
#SBATCH --mail-type=END,FAIL                    # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=shuklas1@chop.edu,farrela@chop.edu           # Where to send mail
#SBATCH -a 1-5000 				# number of threads you want to be run simultaneously, Hist_index times GTEx_index
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32G
#SBATCH -t 40:00:00
#SBATCH --error=Logs_DESeq2/Run_DESeq2-%A_%a.error.out
#SBATCH --output=Logs_DESeq2/Run_DESeq2-%A_%a.out


declare -a input
readarray -t input < indices.txt


function echoMe {
    echo "Running comparions $1 and $2 from job" # $SLURM_ARRAY_TASK_ID = index value & $1 takes array value

    module load R/4.1.0

	Rscript --vanilla run-deseq-analysis.R \
                --hist_file Input_Data/histologies_subset.tsv \
                --counts_file Input_Data/countData_subset.rds \
                --tpm_file ../../data/gene-expression-rsem-tpm-collapsed.rds \
                --ensg_hugo_file ../../data/ensg-hugo-rmtl-mapping.tsv \
                --efo_mondo_file ../../data/efo-mondo-map.tsv \
                --gtex_subgroup_uberon ../../data/uberon-map-gtex-subgroup.tsv \
		--outdir results \
		--HIST_i $1 \
		--GTEX_i $2	

    exit 0
}

echoMe ${input[$SLURM_ARRAY_TASK_ID-1]}


