#!/bin/bash
# 
#SBATCH --job-name=Create_v9_RDS
#
#SBATCH --time=20:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=80G
#SBATCH --error=Create_v9_RDS-%j.out

module load R/4.1.0

Rscript convert_tsv_to_rds.R --tsv_file deseq_all_comparisons.tsv
