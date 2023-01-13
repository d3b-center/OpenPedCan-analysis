#!/bin/bash
# Module authors: Komal S. Rathi, Adam Kraya
# molecular subtype differences
# PediatricOpenTargets 2022

# This script runs the steps for DESeq2 tumor-only analysis with and without RUVg batch correction.

set -e
set -o pipefail

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# Rscript code/01-ruvseq-deseq.R \
# --dataset 'target_nbl' \
# --cohort_values 'TARGET' \
# --cancer_group_values 'Neuroblastoma' \
# --pos_c 'MYCN_targets_M2919_M18532.rds' \
# --neg_c 'hk_genes_normals.rds' \
# --k_value 5

Rscript code/01-ruvseq-deseq.R \
--dataset 'hgg_dmg' \
--cohort_values 'PBTA' \
--cancer_group_values 'High-grade glioma/astrocytoma,Diffuse midline glioma' \
--pos_c '12915_2022_1324_MOESM4_ESM.rds' \
--neg_c 'hk_genes_normals.rds' \
--k_value 5

Rscript code/02-ruvseq-deseq-tn.R \
--dataset 'HGG-DMG_TN' \
--cohort_values 'PBTA,GTEx' \
--cancer_group_values 'Diffuse midline glioma,High-grade glioma/astrocytoma' \
--gtex_subgroups 'Brain - Cortex,Brain - Cerebellum' \
--k_value 5 \
--drop 2 \
--pos_c 'reactome_cell_cycle_msigdb_v7.5.1.rds' \
--neg_c 'hk_genes_normals.rds'
