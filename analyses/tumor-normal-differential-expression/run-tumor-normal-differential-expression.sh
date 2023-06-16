#!/usr/bin/bash
#SBATCH --job-name=Run_Deseq2_v12              # Job Name
#SBATCH --mail-type=END,FAIL                    # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=shuklas1@chop.edu           # Where to send mail
#SBATCH -a 1-5500 				# number of threads you want to be run simultaneously, for v12 input is 102 * 53, so 5406 threads
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=96G
#SBATCH -t 60:00:00
#SBATCH --error=Logs_DESeq2_v12/Run_DESeq2-%A_%a.error.out
#SBATCH --output=Logs_DESeq2_v12/Run_DESeq2-%A_%a.out


declare -a input
readarray -t input < indices.txt



function echoMe {
    echo "Running comparions $1 and $2 from job" # $SLURM_ARRAY_TASK_ID = index value & $1 takes array value

    module load R/4.1.0

        Rscript --vanilla run-deseq-analysis.R \
                --hist_file Input_Data/histologies_subset.tsv \
                --counts_file Input_Data/countData_subset.rds \
                --tpm_file ../../data/gene-expression-rsem-tpm-collapsed.rds \
                --ensg_hugo_file ../../data/ensg-hugo-pmtl-mapping.tsv \
                --efo_mondo_file ../../data/efo-mondo-map.tsv \
                --gtex_subgroup_uberon ../../data/uberon-map-gtex-subgroup.tsv \
		--ind_allcohorts ../../data/independent-specimens.rnaseqpanel.primary.tsv \
		--ind_eachcohort ../../data/independent-specimens.rnaseqpanel.primary.eachcohort.tsv \
		--outdir results \
		--HIST_i $1 \
		--GTEX_i $2	

    exit 0
}

echoMe ${input[$SLURM_ARRAY_TASK_ID-1]}


