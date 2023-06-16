#!/usr/bin/env python3


"""
04-tpm-transcript-representation.py
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Calculate rna-seq expression (tpm) gene isoform (transcript) representation for patients who have samples in both rna-seq and methylation datasets
"""


__author__ = ('Eric Wafula (wafulae@chop.edu)')
__version__ = '1.0'
__date__ = '07 December 2022'


import re
import os
import sys
import git
import argparse
import numpy as np
import pandas as pd
import pyreadr as rds
from scipy.stats import zscore


def read_parameters():
	p = argparse.ArgumentParser(description=("The 04-tpm-transcript-representation.py script calculate rna-seq expression (tpm) gene isoform (transcript) representation for patients who have samples in both rna-seq and methylation datasets."), formatter_class=argparse.RawTextHelpFormatter)
	p.add_argument('HISTOLOGY_FILE', type=str, default=None, help="OPenPedCan histologies file\n\n")
	p.add_argument('RNA_INDEPENDENT_SAMPLES', type=str, default=None, help="OPenPedCan rnaseq independent biospecimen list file\n\n")
	p.add_argument('METHYL_INDEPENDENT_SAMPLES', type=str, default=None, help="OPenPedCan methyl independent biospecimen list file\n\n")
	p.add_argument('GENE_EXP_MATRIX', type=str, default=None, help="OPenPedCan gene expression matrix file\n\n")
	p.add_argument('ISOFORM_EXP_MATRIX', type=str, default=None, help="OPenPedCan isoform expression matrix file\n\n")
	p.add_argument('PROBE_ANNOT', type=str, default=None, help="Methyl gencode array probe annotations\n\n")
	p.add_argument('-v', '--version', action='version', version="04-tpm-transcript-representation.py version {} ({})".format(__version__, __date__), help="Print the current 04-tpm-transcript-representation.py version and exit\n\n")
	return p.parse_args()




def compute_transcript_representation(methyl_histologies, rnaseq_histologies, probe_annot, gene_tpm_values, isoform_tpm_values):
	"""Calculate rna-seq expression (tpm) gene isoform (transcript) representation for patients who have samples in both rna-seq and methylation datasets
	Parameters
	----------
	methyl_histologies : str
		OPenPedCan methylation samples histologies dataframe
	rnaseq_histologies : str
		OPenPedCan RNA-Seq samples histologies dataframe
	probe_annot : str
		Module methylation array probe annotation dataframe
	gene_tpm_values : str
		OPenPedCan RNA-Seq gene expression matrix dataframe
	isoform_tpm_values : str
		OPenPedCan RNA-Seq isoform expression matrix dataframe
	Returns
	-------
	list
		a list of pandas dataframe objects with transcript tmp expression representation for
		cancer types and cohorts with methylation array samples
	"""

	print("=============================================================================")
	print("Calculating rna-seq expression (tpm) gene isoform (transcript) representation")
	print("=============================================================================")
	merging_list = []
	for cohort in methyl_histologies.cohort.unique():
		cohort_type_methyl_ids = methyl_histologies.loc[methyl_histologies.cohort == cohort]
		for cancer_type in cohort_type_methyl_ids.cancer_group.unique():
			print("Calculating rna-seq expression (tpm) gene isoform (transcript) representation for {} cancer group samples in {} cohort...\n".format(cancer_type, cohort))
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

			# Get cancer type gene expression tpm values
			sample_ids = np.append(["Gene_symbol"], cancer_type_ids.RNASeq_ID.unique()).tolist()
			gene_tpm = gene_tpm_values.loc[:,gene_tpm_values.columns.isin(sample_ids)]
			gene_tpm = pd.merge(probe_annot, gene_tpm, how = "inner", on = "Gene_symbol")
			gene_tpm = gene_tpm.drop(columns = ["targetFromSourceId", "Gene_symbol"])

			# Get cancer type isoform expresion tpm values
			sample_ids = np.append(["transcript_id"], cancer_type_ids.RNASeq_ID.unique()).tolist()
			isoform_tpm =  isoform_tpm_values.loc[:,isoform_tpm_values.columns.isin(sample_ids)]
			isoform_tpm = pd.merge(probe_annot, isoform_tpm, how = "inner", on = "transcript_id")
			isoform_tpm = isoform_tpm.drop(columns = ["targetFromSourceId", "Gene_symbol"])
			isoform_tpm = pd.merge(isoform_tpm, gene_tpm["transcript_id"], how = "inner", on = "transcript_id")
			isoform_tpm = isoform_tpm.set_index("transcript_id").rename_axis(None)
			isoform_tpm = isoform_tpm.sort_index(axis=0)
			isoform_tpm = isoform_tpm.sort_index(axis=1)

			# Compute weights for cancer type gene expression tpm values
			gene_tpm = gene_tpm.set_index("transcript_id").rename_axis(None)
			gene_zscore = gene_tpm.apply(zscore, axis = 1).abs()
			gene_weights = gene_zscore.apply(lambda x: 1/np.exp(x))
			gene_weights = gene_weights.sort_index(axis=0)
			gene_weights = gene_weights.sort_index(axis=1)
			gene_weights.fillna(0.00, inplace = True)

			# Compute weighted sum for cancer group isoform expression tpm values
			weigted_isoform_tpm = gene_weights.mul(isoform_tpm, fill_value = 0.00)
			weigted_isoform_tpm["weighted_sum"] = weigted_isoform_tpm.sum(axis=1)

			# Compute weighted sum for cancer type sum of isoform expression tpm values
			isoform_tpm.reset_index(inplace=True)
			isoform_tpm.rename(columns={"index": "transcript_id"}, inplace = True)
			isoform_tpm = pd.merge(probe_annot, isoform_tpm, how = "inner", on = "transcript_id")
			isoform_tpm = isoform_tpm.drop(columns = ["transcript_id", "Gene_symbol"])
			sum_isoform_tpm = isoform_tpm.groupby("targetFromSourceId", as_index=False).sum()
			sum_isoform_tpm = pd.merge(probe_annot, sum_isoform_tpm, how = "inner", on = "targetFromSourceId")
			sum_isoform_tpm = sum_isoform_tpm.drop(columns = ["targetFromSourceId", "Gene_symbol"])
			sum_isoform_tpm = sum_isoform_tpm.set_index("transcript_id").rename_axis(None)
			sum_isoform_tpm = sum_isoform_tpm.sort_index(axis=0)
			sum_isoform_tpm = sum_isoform_tpm.sort_index(axis=1)
			weighted_sum_isoform_tpm = gene_weights.mul(sum_isoform_tpm, fill_value = 0.00)
			weighted_sum_isoform_tpm["weighted_sum"] = weighted_sum_isoform_tpm.sum(axis=1)

			# Compute isoform gene expression tpm representation
			transcript_representation = weigted_isoform_tpm["weighted_sum"].div(weighted_sum_isoform_tpm["weighted_sum"], fill_value = 0.00)
			transcript_representation = pd.Series.to_frame(transcript_representation, name="Transcript_Representation")
			transcript_representation.fillna(0.000000, inplace = True)
			transcript_representation.reset_index(inplace = True)
			transcript_representation.rename(columns={"index": "transcript_id"}, inplace = True)
			transcript_representation["Dataset"] = cohort
			transcript_representation["Disease"] = cancer_type
			gene_transcript_representation = pd.merge(probe_annot, transcript_representation, how = "inner", on = "transcript_id")
			gene_transcript_representation = gene_transcript_representation.drop(columns = ["Gene_symbol"])
			gene_transcript_representation = gene_transcript_representation.groupby(["targetFromSourceId", "Dataset", "Disease"], as_index=False).sum(numeric_only = True).round({"Transcript_Representation": 2})
			gene_transcript_representation = gene_transcript_representation.loc[gene_transcript_representation["Transcript_Representation"] != 0.00]
			gene_transcript_representation = pd.merge(probe_annot, gene_transcript_representation, how = "inner", on = "targetFromSourceId")
			transcript_representation = pd.merge(transcript_representation, gene_transcript_representation[["transcript_id"]], how = "inner", on = "transcript_id")
			transcript_representation["Transcript_Representation"] = transcript_representation["Transcript_Representation"] * 100
			transcript_representation = transcript_representation.round({"Transcript_Representation": 2})
			if not transcript_representation.empty:
				merging_list.append(transcript_representation)
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

	# Get array probes with gencode gene symbols
	annot_cols = ["transcript_id", "targetFromSourceId", "Gene_symbol"]
	probe_annot = pd.read_csv(args.PROBE_ANNOT, usecols = annot_cols, sep="\t", na_filter=False, dtype=str).drop_duplicates().reset_index(drop=True)

	# Get RNA-Seq gene expression tpm values for array probes with gencode gene symbols
	gene_tpm_values = rds.read_r(args.GENE_EXP_MATRIX)[None].reset_index()
	gene_tpm_values.rename(columns={"rownames": "Gene_symbol"}, inplace = True)
	gene_tpm_values = gene_tpm_values[gene_tpm_values["Gene_symbol"].isin(probe_annot["Gene_symbol"].tolist())].drop_duplicates()

	# Get RNA-Seq isoform expression tpm values for array probes with gencode gene symbols
	isoform_tpm_values = rds.read_r(args.ISOFORM_EXP_MATRIX)[None]
	isoform_tpm_values = isoform_tpm_values.loc[:, isoform_tpm_values.columns != "gene_symbol"]
	isoform_tpm_values["transcript_id"] = isoform_tpm_values["transcript_id"].str.extract(r'(\w+)\.\d+')
	isoform_tpm_values = isoform_tpm_values[isoform_tpm_values["transcript_id"].isin(probe_annot["transcript_id"].tolist())].drop_duplicates()

	# Calculating rna-seq expression (tpm) gene isoform (transcript) representation
	merging_list = compute_transcript_representation(methyl_histologies, rnaseq_histologies, probe_annot, gene_tpm_values, isoform_tpm_values)

	# Write rna-seq expression (tpm) gene isoform (transcript) representation values to output file
	transcript_representation = pd.concat(merging_list, sort=False, ignore_index=True)
	transcript_representation.to_csv(os.path.join(results_dir,"methyl-tpm-transcript-representation.tsv.gz"), sep="\t", index=False, encoding="utf-8")


	print("Analysis Done...\n")


if __name__ == "__main__":
	main()