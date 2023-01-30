#!/usr/bin/env python3


"""
06-methly-summary-tsv2jsonl.py
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Convert methylation summary TSV table to JSONL
"""

__author__ = ('Eric Wafula (wafulae@chop.edu)')
__version__ = '2.0'
__date__ = '22 OCtober 2022'


import os 
import sys
import csv
import git
import gzip
import json
import argparse
import numpy as np
import pandas as pd
from collections import OrderedDict

METHLY_VALUES = ["beta", "m"]

def read_parameters():
     p = argparse.ArgumentParser(description=("The 06-methly-summary-tsv2jsonl.py script converts methylation summary table from TSV format to JSONL."), formatter_class=argparse.RawTextHelpFormatter)
     p.add_argument('GENE_SUMMARY_FILE', type=str, default=None, help="Gene-level methyl summary TSV file\n\n")
     p.add_argument('ISOFORM_SUMMARY_FILE', type=str, default=None, help="Isoform-level methyl summary TSV file\n\n")
     p.add_argument('-m', '--methyl_values', type=str, default='beta', choices=METHLY_VALUES, help="OpenPedCan methly matrix values: beta (default) and m\n\n")
     p.add_argument('-v', '--version', action='version', version="06-methly-summary-tsv2jsonl.py version {} ({})".format(__version__, __date__), help="Print the current 06-methly-summary-tsv2jsonl.py version and exit\n\n")
     return p.parse_args()


# establish base dir
root_dir = git.Repo('.', search_parent_directories=True).working_tree_dir

# Set path to module and results directories
module_dir = os.path.join(root_dir, "analyses", "methylation-summary")
results_dir = os.path.join(module_dir, "results")

def tsv_to_jsonl(input_tsv_file, output_jsonl_file):
     """Converts methylation summary table from TSV format to JSONL
     Parameters
     ----------
     input_tsv_file : str
          Gene or isofrom-level methyl summary TSV input file
     output_jsonl_file : str
          Gene or isofrom-level methyl summary JSONL output file name
     Returns
     -------
     None
     """

     methyl_tmp_correlation_tsv = input_tsv_file
     methyl_tmp_correlation_json = output_jsonl_file
     tsv_file = gzip.open(methyl_tmp_correlation_tsv, "rt")
     jsonl_file = gzip.open(methyl_tmp_correlation_json, "wt")
     reader = csv.DictReader(tsv_file, delimiter="\t")
     headers = reader.fieldnames
     for row in reader:
          row_dict = OrderedDict()
          for header in headers:
               row_dict[header] = row[header]
          json.dump(row_dict, jsonl_file)
          jsonl_file.write("\n")
     tsv_file.close()
     jsonl_file.close()

def main():
     # get input parameters
     args = read_parameters()

     print("=======================================================")
     print("Converting methylation summary tables from TSV to JSONL")
     print("=======================================================")
     if (args.methyl_values == "beta"):
          print("\nConverting gene beta-values summary TSV to JSONL...\n")
          tsv_to_jsonl(args.GENE_SUMMARY_FILE, "{}/gene-methyl-beta-values-summary.jsonl.gz".format(results_dir))

          print("Converting isoform beta-values summary TSV to JSONL...\n")
          tsv_to_jsonl(args.ISOFORM_SUMMARY_FILE, "{}/isoform-methyl-beta-values-summary.jsonl.gz".format(results_dir))
     else:
          print("\nConverting gene m-values summary TSV to JSONL...\n")
          tsv_to_jsonl(args.GENE_SUMMARY_FILE, "{}/gene-methyl-m-values-summary.jsonl.gz".format(results_dir))

          print("Converting isoform m-values summary TSV to JSONL...\n")
          tsv_to_jsonl(args.ISOFORM_SUMMARY_FILE, "{}/isoform-methyl-m-values-summary.jsonl.gz".format(results_dir))

     print("Done converting TSV to JSONL...\n")

if __name__ == "__main__":
     main()