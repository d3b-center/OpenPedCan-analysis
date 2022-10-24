#!/usr/bin/env python3


"""
06-methly-summary-tsv2jsonl.py
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Convert methylation summary TSV table to JSONL
"""


__author__ = ('Eric Wafula (wafulae@chop.edu)')
__version__ = '1.0'
__date__ = '15 May 2022'


import os 
import sys
import csv
import git
import gzip
import json
import numpy as np
import pandas as pd
from collections import OrderedDict


# establish base dir
root_dir = git.Repo('.', search_parent_directories=True).working_tree_dir

# Set path to module and results directories
module_dir = os.path.join(root_dir, "analyses", "methylation-summary")
results_dir = os.path.join(module_dir, "results")

print(f"\nConverting TSV to JSONL...\n")

beta_tmp_correlation_tsv = f"{results_dir}/methyl-beta-values-summary.tsv.gz"
beta_tmp_correlation_json = f"{results_dir}/methyl-beta-values-summary.jsonl.gz"
tsv_file = gzip.open(beta_tmp_correlation_tsv, "rt")
jsonl_file = gzip.open(beta_tmp_correlation_json, "wt")
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

print(f"Done converting TSV to JSONL...\n")
