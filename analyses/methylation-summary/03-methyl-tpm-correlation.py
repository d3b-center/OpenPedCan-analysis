#!/usr/bin/env python3


"""
03-methyl-tpm-correlation.py
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Calculate representative probe-level correlations between rna-seq (tpm) and methylation (beta/m-vlaues) for patients who have samples in both datasets
"""


__author__ = ('Eric Wafula (wafulae@chop.edu)')
__version__ = '2.0'
__date__ = '17 October 2022'


import re
import os
import sys
import git
import argparse
import numpy as np
import pandas as pd
import pyreadr as rds


TUMOR_DESCRIPTOR = ["primary", "relapse"]
METHLY_VALUES = ["beta", "m"]
EXP_TYPE = ["gene", "isoform"]


def read_parameters():
	p = argparse.ArgumentParser(description=("The 03-methyl-tpm-correlation.py script calculate representative probe-level correlations between rna-seq (tpm) and methylation (beta/m-values) for patients who have samples in both datasets."), formatter_class=argparse.RawTextHelpFormatter)
	p.add_argument('HISTOLOGY_FILE', type=str, default=None, help="OPenPedCan histologies file\n\n")
	p.add_argument('RNA_INDEPENDENT_SAMPLES', type=str, default=None, help="OPenPedCan rnaseq independent biospecimen list file\n\n")
	p.add_argument('METHYL_INDEPENDENT_SAMPLES', type=str, default=None, help="OPenPedCan methyl independent biospecimen list file\n\n")
	p.add_argument('METHLY_MATRIX', type=str, default=None, help="OpenPedCan methyl beta-values or m-values matrix file\n\n")
	p.add_argument('EXP_MATRIX', type=str, default=None, help="OPenPedCan expression matrix file\n\n")
	p.add_argument('PROBE_ANNOT', type=str, default=None, help="Methylation aaray probe gencode annotation results file\n\n")
	p.add_argument('-m', '--methyl_values', type=str, default='beta', choices=METHLY_VALUES, help="OpenPedCan methly matrix values: beta (default) and m\n\n")
	p.add_argument('-e', '--exp_values', type=str, default='gene', choices=EXP_TYPE, help="OpenPedCan expression matrix values: gene (default) and isoform\n\n")
	p.add_argument('-v', '--version', action='version', version="03-methyl-tpm-correlation.py version {} ({})".format(__version__, __date__), help="Print the current 03-methyl-tpm-correlation.py version and exit\n\n")
	return p.parse_args()



def compute_correlation(methyl_histologies, rnaseq_histologies, meth_values, tpm_values):
	"""Calculates probe-level correlations between RNA-Seq (TPM) and preprocessed methyl (beta/m-values) samples
	Parameters
	----------
	methyl_histologies : str
		OPenPedCan methylation samples histologies dataframe
	rnaseq_histologies : str
		OPenPedCan RNA-Seq samples histologies dataframe
	meth_values : str
		OPenPedCan methylation arrays matrix dataframe
	tpm_values : str
		OPenPedCan RNA-Seq expression matrix dataframe
	Returns
	-------
	list
		a list of pandas dataframe objects with probe beta/m-values to tmp-values correlations for
		cancer types and cohorts with methylation array samples
	"""

	print("===========================================================================================")
	print("Calculating probe-level correlations between methyl beta/m-values and expression tpm values")
	print("===========================================================================================")
	merging_list = []
	for cohort in methyl_histologies.cohort.unique():
		cohort_type_methyl_ids = methyl_histologies.loc[methyl_histologies.cohort == cohort]
		for cancer_type in cohort_type_methyl_ids.cancer_group.unique():
			print("Calculating probe-level correlations between beta/m-values and tpm values for {} cancer group samples in {} cohort...\n".format(cancer_type, cohort))
			# Get cancer type patients with both methyl and RNA-Seq data
			cancer_type_rnaseq_ids = rnaseq_histologies.loc[(rnaseq_histologies.cohort == cohort) & (rnaseq_histologies.cancer_group == cancer_type)]
			cancer_type_rnaseq_ids = cancer_type_rnaseq_ids[["Kids_First_Biospecimen_ID", "Kids_First_Participant_ID"]]
			cancer_type_rnaseq_ids.rename(columns={"Kids_First_Biospecimen_ID": "RNASeq_ID"}, inplace = True)
			cancer_type_meth_ids = methyl_histologies.loc[(methyl_histologies.cohort == cohort) & (methyl_histologies.cancer_group == cancer_type)]
			cancer_type_meth_ids = cancer_type_meth_ids[["Kids_First_Biospecimen_ID", "Kids_First_Participant_ID"]]
			cancer_type_meth_ids.rename(columns={"Kids_First_Biospecimen_ID": "Meth_ID"}, inplace = True)
			cancer_type_ids = pd.merge(cancer_type_meth_ids, cancer_type_rnaseq_ids, how = "inner", on = "Kids_First_Participant_ID")
			cancer_type_ids.rename(columns={"Kids_First_Participant_ID": "Patient_ID"}, inplace = True)
			if cancer_type_ids.empty:
				continue

			# Get cancer type beta/m-values for patients with both RNA-Seq and methylation data
			sample_ids = np.append(["match_id"], cancer_type_ids.Meth_ID.unique()).tolist()
			cancer_type_methyl = meth_values.loc[:,meth_values.columns.isin(sample_ids)].groupby("match_id", as_index=False).median()
			cancer_type_methyl = cancer_type_methyl.set_index("match_id").rename_axis(None)
			cancer_type_methyl = cancer_type_methyl.transpose().reset_index()
			cancer_type_methyl.rename(columns={"index": "Meth_ID"}, inplace = True)
			cancer_type_methyl.dropna(axis = 1, how = "all", inplace = True)
			cancer_type_methyl = pd.merge(cancer_type_ids, cancer_type_methyl, how = "inner", on = "Meth_ID")
			cancer_type_methyl = cancer_type_methyl.loc[:, ~cancer_type_methyl.columns.isin(["Meth_ID", "RNASeq_ID"])]
			cancer_type_methyl = cancer_type_methyl.groupby("Patient_ID", as_index=False).median()

			# Get cancer type tpm values for patients with both RNA-Seq and methylation data
			sample_ids = np.append(["match_id"], cancer_type_ids.RNASeq_ID.unique()).tolist()
			cancer_type_tpm = tpm_values.loc[:,tpm_values.columns.isin(sample_ids)].groupby("match_id", as_index=False).median()
			cancer_type_tpm = cancer_type_tpm.set_index("match_id").rename_axis(None)
			cancer_type_tpm = cancer_type_tpm.transpose().reset_index()
			cancer_type_tpm.rename(columns={"index": "RNASeq_ID"}, inplace = True)
			cancer_type_tpm.dropna(axis = 1, how = "all", inplace = True)
			cancer_type_tpm = pd.merge(cancer_type_ids, cancer_type_tpm, how = "inner", on = "RNASeq_ID")
			cancer_type_tpm = cancer_type_tpm.loc[:, ~cancer_type_tpm.columns.isin(["Meth_ID", "RNASeq_ID"])]
			cancer_type_tpm = cancer_type_tpm.groupby("Patient_ID", as_index=False).median()

			# calculate probe correlation between methylation beta values RNA-Seq expression tpm values
			cancer_type_methyl = cancer_type_methyl.sort_values(by = "Patient_ID").set_index("Patient_ID").rename_axis(None)
			cancer_type_tpm = cancer_type_tpm.sort_values(by = "Patient_ID").set_index("Patient_ID").rename_axis(None)
			cancer_type_correlation = cancer_type_methyl.corrwith(cancer_type_tpm, drop = True).dropna().to_frame().reset_index()
			cancer_type_correlation.rename(columns = {0: "RNA_Correlation", "index": "match_id"}, inplace = True)
			cancer_type_correlation["Dataset"] = cohort
			cancer_type_correlation["Disease"] = cancer_type
			if not cancer_type_correlation.empty:
				merging_list.append(cancer_type_correlation)
	return(merging_list)


def main():
	# get input parameters
	args = read_parameters()

	# establish base dir
	root_dir = git.Repo('.', search_parent_directories=True).working_tree_dir

	# Set path to module and results directories
	data_dir = os.path.join(root_dir, "data")
	module_dir = os.path.join(root_dir, "analyses", "methylation-summary")
	results_dir = os.path.join(module_dir, "results")

	print("\nStarting Analysis...\n")

	# get primary and relapse indepedent samples
	rnaseq_independent_samples = pd.read_csv(args.RNA_INDEPENDENT_SAMPLES, sep="\t", na_filter=False, dtype=str)
	methyl_independent_samples = pd.read_csv(args.METHYL_INDEPENDENT_SAMPLES, sep="\t", na_filter=False, dtype=str)

	# Get required columns from histologies file for rnaseq and methyl sample IDs
	hist_cols = ["Kids_First_Biospecimen_ID", "Kids_First_Participant_ID", "experimental_strategy", "sample_type", "tumor_descriptor","cohort", "cancer_group"]
	histologies = pd.read_csv(args.HISTOLOGY_FILE, usecols = hist_cols, sep="\t", na_filter=False, dtype=str)
	histologies = histologies[histologies["cancer_group"] != "NA"]
	rnaseq_histologies = histologies[histologies["Kids_First_Biospecimen_ID"].isin(rnaseq_independent_samples["Kids_First_Biospecimen_ID"].tolist())]
	methyl_histologies = histologies[histologies["Kids_First_Biospecimen_ID"].isin(methyl_independent_samples["Kids_First_Biospecimen_ID"].tolist())]
	del(histologies)

	# Get methyl beta or m-values and only keep samples in independent sample list
	meth_values = ""
	if args.exp_values == "gene":
		meth_values = rds.read_r(args.METHLY_MATRIX)[None]
		meth_values = meth_values[["Probe_ID"] + methyl_independent_samples["Kids_First_Biospecimen_ID"].tolist()]
		annot_cols = ["Probe_ID", "targetFromSourceId"]
		probe_annot = pd.read_csv(args.PROBE_ANNOT, usecols = annot_cols, sep="\t", na_filter=False, dtype=str).drop_duplicates().reset_index(drop=True)
		meth_values = pd.merge(probe_annot, meth_values, how = "inner", on = "Probe_ID")
		meth_values["match_id"] = meth_values[["Probe_ID", "targetFromSourceId"]].agg("-".join, axis=1)
		meth_values = meth_values.drop(columns = ["Probe_ID", "targetFromSourceId"])
	else:
		meth_values = rds.read_r(args.METHLY_MATRIX)[None]
		meth_values = meth_values[["Probe_ID"] + methyl_independent_samples["Kids_First_Biospecimen_ID"].tolist()]
		annot_cols = ["Probe_ID", "transcript_id"]
		probe_annot = pd.read_csv(args.PROBE_ANNOT, usecols = annot_cols, sep="\t", na_filter=False, dtype=str).drop_duplicates().reset_index(drop=True)
		meth_values = pd.merge(probe_annot, meth_values, how = "inner", on = "Probe_ID")
		meth_values["match_id"] = meth_values[["Probe_ID", "transcript_id"]].agg("-".join, axis=1)
		meth_values = meth_values.drop(columns = ["Probe_ID", "transcript_id"])		

	# Get RNA-Seq expression tpm values for array probes with gencode gene symbols 
	# and merge probe annotations to tpm matrix
	tpm_values = ""
	if args.exp_values == "gene":
		tpm_values = rds.read_r(args.EXP_MATRIX)[None].reset_index()
		if "rownames" in tpm_values.columns:
			tpm_values.rename(columns={"rownames": "Gene_symbol"}, inplace = True)
		elif "index" in tpm_values.columns:
			tpm_values.rename(columns={"index": "Gene_symbol"}, inplace = True)
		annot_cols = ["Probe_ID", "targetFromSourceId", "Gene_symbol"]
		probe_annot = pd.read_csv(args.PROBE_ANNOT, usecols = annot_cols, sep="\t", na_filter=False, dtype=str).drop_duplicates().reset_index(drop=True)
		tpm_values = pd.merge(probe_annot, tpm_values, how = "inner", on = "Gene_symbol")
		tpm_values["match_id"] = tpm_values[["Probe_ID", "targetFromSourceId"]].agg("-".join, axis=1)
		tpm_values = tpm_values.drop(columns = ["Probe_ID", "targetFromSourceId", "Gene_symbol"])
	else:
		tpm_values = rds.read_r(args.EXP_MATRIX)[None]
		tpm_values = tpm_values.loc[:, tpm_values.columns != "gene_symbol"]
		tpm_values["transcript_id"] = tpm_values["transcript_id"].str.extract(r'(\w+)\.\d+')
		annot_cols = ["Probe_ID", "transcript_id"]
		probe_annot = pd.read_csv(args.PROBE_ANNOT, usecols = annot_cols, sep="\t", na_filter=False, dtype=str).drop_duplicates().reset_index(drop=True)
		tpm_values = pd.merge(probe_annot, tpm_values, how = "inner", on = "transcript_id")
		tpm_values["match_id"] = tpm_values[["Probe_ID", "transcript_id"]].agg("-".join, axis=1)
		tpm_values = tpm_values.drop(columns = ["Probe_ID", "transcript_id"]) 

	# Calculating probe-level correlations between methyl beta/m-values and expression tpm values
	merging_list = compute_correlation(methyl_histologies, rnaseq_histologies, meth_values, tpm_values)

	# Write probe-level correlations between methyl beta/m-values RNA-Seq expression tpm values to output file
	if args.methyl_values == "beta":
		print("Writing probe-level correlations to methyl-probe-beta-tpm-correlations.tsv file...\n")
		beta_tmp_correlation = pd.concat(merging_list, sort=False, ignore_index=True)
		match_values = beta_tmp_correlation["match_id"].str.split("-", n = 1, expand = True)
		if args.exp_values == "gene":
			beta_tmp_correlation["Probe_ID"]= match_values[0]
			beta_tmp_correlation["targetFromSourceId"]= match_values[1]
			beta_tmp_correlation = beta_tmp_correlation.drop(columns = ["match_id"])
			beta_tmp_correlation.to_csv(os.path.join(results_dir,"gene-methyl-probe-beta-tpm-correlations.tsv.gz"), sep="\t", index=False, encoding="utf-8")
		else:
			beta_tmp_correlation["Probe_ID"]= match_values[0]
			beta_tmp_correlation["transcript_id"]= match_values[1]
			beta_tmp_correlation = beta_tmp_correlation.drop(columns = ["match_id"])
			beta_tmp_correlation.to_csv(os.path.join(results_dir,"isoform-methyl-probe-beta-tpm-correlations.tsv.gz"), sep="\t", index=False, encoding="utf-8")
	else:
		print("Writing probe-level correlations to methyl-probe-m-tpm-correlations.tsv file...\n")
		m_tmp_correlation = pd.concat(merging_list, sort=False, ignore_index=True)
		match_values = m_tmp_correlation["match_id"].str.split("-", n = 1, expand = True)
		if args.exp_values == "gene":
			m_tmp_correlation["Probe_ID"]= match_values[0]
			m_tmp_correlation["targetFromSourceId"]= match_values[1]
			m_tmp_correlation = m_tmp_correlation.drop(columns = ["match_id"])
			m_tmp_correlation.to_csv(os.path.join(results_dir,"gene-methyl-probe-m-tpm-correlations.tsv.gz"), sep="\t", index=False, encoding="utf-8")
		else:
			m_tmp_correlation["Probe_ID"]= match_values[0]
			m_tmp_correlation["transcript_id"]= match_values[1]
			m_tmp_correlation = m_tmp_correlation.drop(columns = ["match_id"])
			m_tmp_correlation.to_csv(os.path.join(results_dir,"isoform-methyl-probe-m-tpm-correlations.tsv.gz"), sep="\t", index=False, encoding="utf-8")

	print("Analysis Done...\n")


if __name__ == "__main__":
	main()