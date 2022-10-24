## Nhat Duong & J Shapiro
## 2019 - 2020


# Imports in the pep8 order https://www.python.org/dev/peps/pep-0008/#imports
# Standard library
import argparse
import subprocess
import sys
import os

# Related third party
import numpy as np
import pandas as pd

## Define the callers and the extension to give the intermediate files
extensions = {"gatk": ".gatk", "cnvkit": ".cnvkit", "freec": ".freec"}

# Define the column headers for IDs
id_headers = {
    "gatk": "BS_ID",
    "cnvkit": "ID",
    "freec": "Kids_First_Biospecimen_ID",
}

parser = argparse.ArgumentParser(
    description="""This script splits CNV files
                                                into one per sample. It also
                                                prints a snakemake config file
                                                to the specified filename."""
)
parser.add_argument("--gatk", required=True, help="path to the gatk file")
parser.add_argument("--cnvkit", required=True, help="path to the cnvkit file")
parser.add_argument("--freec", required=True, help="path to the freec file")
parser.add_argument("--histologies", required=True, help="path to the histology file")
parser.add_argument("--snake", required=True, help="path for snakemake config file")
parser.add_argument("--scratch", required=True, help="directory for scratch files")
parser.add_argument(
    "--uncalled",
    required=True,
    help="path for the table of sample-caller outputs removed and not called for too many CNVs",
)
parser.add_argument(
    "--maxcnvs", default=2500, help="samples with more than 2500 cnvs are set to blank"
)
parser.add_argument("--cnvsize", default=3000, help="cnv cutoff size in base pairs")
parser.add_argument("--freecp", default=0.01, help="p-value cutoff for freec")


args = parser.parse_args()
scratch_d = args.scratch

# Read data files and get sample counts
caller_dfs = {}
samples = {}
out_dirs = {}
for caller in extensions.keys():
    # use vars() to access args Namespace as dictionary
    my_file = vars(args)[caller]
    my_df = pd.read_csv(my_file, delimiter="\t", dtype=str)
    id = id_headers[caller]
    my_samples = set(my_df[id])
    ## Define and create assumed directories
    my_dn = "_".join([caller, caller])
    my_dir = os.path.join(scratch_d, my_dn)
    if not os.path.exists(my_dir):
        os.makedirs(my_dir)
    caller_dfs[caller] = my_df
    samples[caller] = my_samples
    out_dirs[caller] = my_dir

# Read histology file
histologies = pd.read_csv(args.histologies, sep="\t", dtype=str)

# Filtering for WGS samples
WGS_all_samples = set(
    histologies[
        (histologies["experimental_strategy"] == "WGS")
        & (histologies["sample_type"] == "Tumor")
    ]["Kids_First_Biospecimen_ID"]
)
print(len(WGS_all_samples))

## Merged and take the unique samples. Any method without a certain sample will get an empty file
## for of that sample.
all_samples = set().union(*samples.values())

## Intersect WGS DNA samples with all_samples to run cnv consensus
WGS_all_samples_to_run = WGS_all_samples.intersection(all_samples)
print(len(WGS_all_samples_to_run))


bad_calls = []

## Loop through each sample, search for that sample in each of the three dataframes,
## and create a file of the sample in each directory
for sample in WGS_all_samples_to_run:
    for caller in extensions.keys():
        # get caller specific variables
        my_ext = extensions[caller]
        my_df = caller_dfs[caller]
        my_id = id_headers[caller]
        my_dir = out_dirs[caller]

        # find samples in df
        export = my_df.loc[my_df[my_id] == sample]

        ## Write cnvs to file if less than maxcnvs / otherwise empty file and add to bad_calls list
        with open(os.path.join(my_dir, sample + my_ext), "w") as file_out:
            if export.shape[0] <= args.maxcnvs and export.shape[0] > 0:
                export.to_csv(file_out, sep="\t", index=False)
            else:
                bad_calls.append(sample + "\t" + caller + "\n")

## Make the Snakemake config file. Write all of the sample names into the config file
with open(args.snake, "w") as file:
    file.write("samples:" + "\n")
    for sample in WGS_all_samples_to_run:
        file.write("  " + str(sample) + ":" + "\n")

    ## Define the extension for the config file
    for caller in extensions.keys():
        file.write(caller + "_ext: " + extensions[caller] + "\n")

    ## Define location for python scripts and scratch
    file.write("scripts: " + os.path.dirname(os.path.realpath(__file__)) + "\n")
    file.write("scratch: " + scratch_d + "\n")

    ## Define the size cutoff and freec's pval cut off.
    file.write("size_cutoff: " + str(args.cnvsize) + "\n")
    file.write("freec_pval: " + str(args.freecp) + "\n")

## Write out the bad calls file
bad_calls.sort()
with open(args.uncalled, "w") as file:
    file.write("sample\tcaller\n")
    file.writelines(bad_calls)
