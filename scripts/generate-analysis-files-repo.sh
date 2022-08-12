#!/bin/sh

set -e
set -o pipefail

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# If RUN_LOCAL is used, the time-intensive steps are skipped because they cannot
# be run on a local computer -- the idea is that setting RUN_LOCAL=1 will allow for
# local testing running/testing of all other steps
RUN_LOCAL=${RUN_LOCAL:-0}

# Get base directory of project
cd ..
BASEDIR="$(pwd)"
cd -
  
analyses_dir="$BASEDIR/analyses"
data_dir="$BASEDIR/data"
scratch_dir="$BASEDIR/scratch"

OPENPBTA_BASE_SUBTYPING=0

# Compile all the files that need to be included in the release in one place
# in the scratch directory
compiled_dir=${scratch_dir}/analysis_files_for_release
mkdir -p ${compiled_dir}

# Create the independent sample list using the *FULL* histology file
echo "Create independent sample list"
bash ${analyses_dir}/independent-samples/run-independent-samples.sh

# Fusion summary
echo "Run fusion summary for subtypes"
bash ${analyses_dir}/fusion-summary/run-new-analysis.sh

# Copy over independent specimen lists
cp ${analyses_dir}/independent-samples/results/independent-specimens.*  ${compiled_dir}

# Copy over fusion summary
cp ${analyses_dir}/fusion-summary/results/* ${compiled_dir}

# Run TMB step
echo "Create TMB results"
bash ${analyses_dir}/tmb-calculation/run_tmb_calculation.sh

# Copy over TMB results
cp ${analyses_dir}/tmb-calculation/results/snv-mutation-tmb-coding.tsv ${compiled_dir}
cp ${analyses_dir}/tmb-calculation/results/snv-mutation-tmb-all.tsv ${compiled_dir}


# Create an md5sum file for all the files in the directory where the analysis
# files are compiled
cd ${compiled_dir}
# Remove old file if it exists
rm -f analysis_files_repo_md5sum.txt
# Create a new md5sum.txt file
md5sum * > analysis_files_repo_md5sum.txt
