#!/usr/bin/env python3


"""
04-beta-tpm-correlation.py
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Calculate representative probe-level correlations between RNA-Seq (TPM) and methylation (Beta) for patients who have samples in both datasets
"""


__author__ = ('Eric Wafula (wafulae@chop.edu)')
__version__ = '1.0'
__date__ = '15 May 2022'


import re
import os
import sys
import git
import numpy as np
import pandas as pd
import pyreadr as rds


# establish base dir
root_dir = git.Repo('.', search_parent_directories=True).working_tree_dir

# Set path to module and results directories
data_dir = os.path.join(root_dir, "data")
module_dir = os.path.join(root_dir, "analyses", "methylation-summary")
results_dir = os.path.join(module_dir, "results")

print(f"\nStarting Analysis...\n")

# Get required columns from histologies file for RNA-Seq and methyalation sample IDs
hist_cols = ["Kids_First_Biospecimen_ID", "Kids_First_Participant_ID", "experimental_strategy", "sample_type", "tumor_descriptor","cohort", "cancer_group"]
histologies = pd.read_csv(os.path.join(data_dir, "histologies.tsv"), usecols = hist_cols, sep="\t", na_filter=False, dtype=str)
rnaseq_histologies = histologies.loc[((histologies.tumor_descriptor == "Primary Tumor") | (histologies.tumor_descriptor == "Initial CNS Tumor")) & (histologies.experimental_strategy == "RNA-Seq")]
meth_histologies = histologies.loc[((histologies.tumor_descriptor == "Primary Tumor") | (histologies.tumor_descriptor == "Initial CNS Tumor")) & (histologies.experimental_strategy == "Methylation")]
del(histologies)

# Get methylation beta values
beta = rds.read_r(os.path.join(results_dir, "methyl-beta-values.rds"))[None]

# Get RNA-Seq expression TPM values for array probes in GENCODE version 38 (Ensembl 104) gene symbols
tpm = rds.read_r(os.path.join(data_dir,"gene-expression-rsem-tpm-collapsed.rds"))[None].reset_index()
tpm.rename(columns={"rownames": "Gene_symbol"}, inplace = True)

# Get array probes in GENCODE version 38 (Ensembl 104) gene symbols
annot_cols = ["Probe_ID", "Gene_symbol"]
probe_annot = pd.read_csv(os.path.join(results_dir, "methyl-probe-annotations.tsv.gz"), usecols = annot_cols, sep="\t", na_filter=False, dtype=str).drop_duplicates().reset_index(drop=True)

# merge probe annotations to tpm matrix
tpm = pd.merge(probe_annot, tpm, how = "inner", on = "Gene_symbol")
tpm = tpm.loc[:, tpm.columns != "Gene_symbol"]

# Calculating representative probe-level correlations between RNA-Seq (TPM) and preprocessed methylation (Beta) samples
print(f"========================================================================================")
print(f"Calculating probe-level correlations between methylation beta and expression tpm values")
print(f"========================================================================================\n")
merging_list = []
for cohort in meth_histologies.cohort.unique():
	cohort_type_meth_ids = meth_histologies.loc[meth_histologies.cohort == cohort]
	for cancer_type in cohort_type_meth_ids.cancer_group.unique():
		print(f"Calculating probe-level correlations between beta and tpm values for {cancer_type} cancer group samples in {cohort} cohort...\n")
		# Get cancer type patients with both methylation and RNA-Seq data
		cancer_type_rnaseq_ids = rnaseq_histologies.loc[(rnaseq_histologies.cohort == cohort) & (rnaseq_histologies.cancer_group == cancer_type)]
		cancer_type_rnaseq_ids = cancer_type_rnaseq_ids[["Kids_First_Biospecimen_ID", "Kids_First_Participant_ID"]]
		cancer_type_rnaseq_ids.rename(columns={"Kids_First_Biospecimen_ID": "RNASeq_ID"}, inplace = True)
		cancer_type_meth_ids = meth_histologies.loc[(meth_histologies.cohort == cohort) & (meth_histologies.cancer_group == cancer_type)]
		cancer_type_meth_ids = cancer_type_meth_ids[["Kids_First_Biospecimen_ID", "Kids_First_Participant_ID"]]
		cancer_type_meth_ids.rename(columns={"Kids_First_Biospecimen_ID": "Meth_ID"}, inplace = True)
		cancer_type_ids = pd.merge(cancer_type_meth_ids, cancer_type_rnaseq_ids, how = "inner", on = "Kids_First_Participant_ID")
		cancer_type_ids.rename(columns={"Kids_First_Participant_ID": "Patient_ID"}, inplace = True)
		if cancer_type_ids.empty:
			continue

		# Get cancer type beta values for patients with both RNA-Seq and methylation data
		sample_ids = np.append(["Probe_ID"], cancer_type_ids.Meth_ID.unique()).tolist()
		cancer_type_beta = beta.loc[:,beta.columns.isin(sample_ids)].groupby("Probe_ID", as_index=False).median()
		cancer_type_beta = cancer_type_beta.set_index("Probe_ID").rename_axis(None)
		cancer_type_beta = cancer_type_beta.transpose().reset_index()
		cancer_type_beta.rename(columns={"index": "Meth_ID"}, inplace = True)
		cancer_type_beta.dropna(axis = 1, how = "all", inplace = True)
		cancer_type_beta = pd.merge(cancer_type_ids, cancer_type_beta, how = "inner", on = "Meth_ID")
		cancer_type_beta = cancer_type_beta.loc[:, ~cancer_type_beta.columns.isin(["Meth_ID", "RNASeq_ID"])]
		cancer_type_beta = cancer_type_beta.groupby("Patient_ID", as_index=False).median()

		# Get cancer type tpm values for patients with both RNA-Seq and methylation data
		sample_ids = np.append(["Probe_ID"], cancer_type_ids.RNASeq_ID.unique()).tolist()
		cancer_type_tpm = tpm.loc[:,tpm.columns.isin(sample_ids)].groupby("Probe_ID", as_index=False).median()
		cancer_type_tpm = cancer_type_tpm.set_index("Probe_ID").rename_axis(None)
		cancer_type_tpm = cancer_type_tpm.transpose().reset_index()
		cancer_type_tpm.rename(columns={"index": "RNASeq_ID"}, inplace = True)
		cancer_type_tpm.dropna(axis = 1, how = "all", inplace = True)
		cancer_type_tpm = pd.merge(cancer_type_ids, cancer_type_tpm, how = "inner", on = "RNASeq_ID")
		cancer_type_tpm = cancer_type_tpm.loc[:, ~cancer_type_tpm.columns.isin(["Meth_ID", "RNASeq_ID"])]
		cancer_type_tpm = cancer_type_tpm.groupby("Patient_ID", as_index=False).median()

		# calculate probe correlation between methylation beta values RNA-Seq expression tpm values
		cancer_type_beta = cancer_type_beta.sort_values(by = "Patient_ID").set_index("Patient_ID").rename_axis(None)
		cancer_type_tpm = cancer_type_tpm.sort_values(by = "Patient_ID").set_index("Patient_ID").rename_axis(None)
		cancer_type_correlation = cancer_type_beta.corrwith(cancer_type_tpm, drop = True).dropna().to_frame().reset_index()
		cancer_type_correlation.rename(columns = {0: "RNA_Correlation", "index": "Probe_ID"}, inplace = True)
		cancer_type_correlation["Dataset"] = cohort
		cancer_type_correlation["Disease"] = cancer_type
		if not cancer_type_correlation.empty:
			merging_list.append(cancer_type_correlation)

# Write probe-level correlations between methylation beta values RNA-Seq expression tpm values
print(f"Writing probe-level correlations to methyl-probe-beta-tpm-correlations.tsv file...\n")
beta_tmp_correlation = pd.concat(merging_list, sort=False, ignore_index=True)
beta_tmp_correlation.to_csv(os.path.join(results_dir,"methyl-probe-beta-tpm-correlations.tsv.gz"), sep="\t", index=False, encoding="utf-8")

print(f"Analysis Done...\n")

