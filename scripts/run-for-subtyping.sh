#!/bin/sh

set -e
set -o pipefail

printf "Start generating pre-release files...\n\n"

# Set locations for s3 bucket that contains subtyping commit files
URL="s3://d3b-openaccess-us-east-1-prd-pbta/open-targets"
COMMIT="analysis-files-pre-release-commit"

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

# Compile all the files that need to be examined for changes in one place
# in the scratch directory
commit_dir="${scratch_dir}/analysis-files-pre-release-commit"
mkdir -p ${commit_dir}

# Create the independent sample list using the *base* histology file (i.e. - histologies-base.tsv)
echo "Create independent sample list for fusion filtering module"
cd ${analyses_dir}/independent-samples
OPENPBTA_BASE_SUBTYPING=1 bash run-independent-samples.sh

## Run subtyping modules

# Run MB subtyping
echo "Run MB subtyping"
cd ${analyses_dir}/molecular-subtyping-MB
bash run-molecular-subtyping-mb.sh

# Copy over MB subtyping
cp ${analyses_dir}/molecular-subtyping-MB/results/MB_molecular_subtype.tsv ${commit_dir}
cp ${analyses_dir}/molecular-subtyping-MB/results/mb-classified.rds ${commit_dir}

# Run CRANIO subtyping
echo "Run CRANIO subtyping"
cd ${analyses_dir}/molecular-subtyping-CRANIO
bash run-molecular-subtyping-cranio.sh

# Copy over CRANIO subtyping
cp ${analyses_dir}/molecular-subtyping-CRANIO/results/CRANIO_defining_lesions.tsv ${commit_dir}
cp ${analyses_dir}/molecular-subtyping-CRANIO/results/CRANIO_molecular_subtype.tsv ${commit_dir}

# Run EPN subtyping
echo "Run EPN subtyping"
cd ${analyses_dir}/molecular-subtyping-EPN
bash run-molecular-subtyping-EPN.sh

# Copy over EPN subtyping
cp ${analyses_dir}/molecular-subtyping-EPN/results/EPN_all_data.tsv ${commit_dir}
cp ${analyses_dir}/molecular-subtyping-EPN/results/EPN_all_data_withsubgroup.tsv ${commit_dir}

# Run Embryonal subtyping
echo "Run Embryonal subtyping"
cd ${analyses_dir}/molecular-subtyping-embryonal
bash run-embryonal-subtyping.sh

# Copy over Embryonal subtyping
cp ${analyses_dir}/molecular-subtyping-embryonal/results/embryonal_tumor_molecular_subtypes.tsv ${commit_dir}
cp ${analyses_dir}/molecular-subtyping-embryonal/results/embryonal_tumor_subtyping_relevant_data.tsv ${commit_dir}

# Run chordoma subtyping
echo "Run chordoma subtyping"
cd ${analyses_dir}/molecular-subtyping-chordoma
bash run-molecular-subtyping-chordoma.sh

# Copy over chordoma subtyping
cp ${analyses_dir}/molecular-subtyping-chordoma/results/chordoma_smarcb1_status.tsv ${commit_dir}

# Run EWS subtyping
echo "Run EWS subtyping"
cd ${analyses_dir}/molecular-subtyping-EWS
bash run_subtyping.sh

# Copy over EWS subtyping
cp ${analyses_dir}/molecular-subtyping-EWS/results/EWS_results.tsv ${commit_dir}

# Run neurocytoma subtyping
echo "Run neurocytoma subtyping"
cd ${analyses_dir}/molecular-subtyping-neurocytoma
bash run_subtyping.sh

# Copy over neurocytoma subtyping
cp ${analyses_dir}/molecular-subtyping-neurocytoma/results/neurocytoma_subtyping.tsv ${commit_dir}

# Run HGG subtyping
echo "Run HGG subtyping"
cd ${analyses_dir}/molecular-subtyping-HGG
bash run-molecular-subtyping-HGG.sh

# Copy over neurocytoma subtyping
cp ${analyses_dir}/molecular-subtyping-HGG/results/*.tsv ${commit_dir}

# Run LGAT subtyping
echo "Run LGAT subtyping"
cd ${analyses_dir}/molecular-subtyping-LGAT
bash run_subtyping.sh

# Copy over LGAT subtyping
cp ${analyses_dir}/molecular-subtyping-LGAT/results/lgat_subtyping.tsv ${commit_dir}

# Run NBL subtyping
echo "Run NBL subtyping"
cd ${analyses_dir}/molecular-subtyping-NBL
bash run-molecular-subtyping-NBL.sh

# Copy over NBL subtyping
cp ${analyses_dir}/molecular-subtyping-NBL/results/*.tsv ${commit_dir}

# Run ATRT subtyping
echo "Run ATRT subtyping"
cd ${analyses_dir}/molecular-subtyping-ATRT
bash run-molecular-subtyping-ATRT.sh

# Copy over ATRT subtyping
cp ${analyses_dir}/molecular-subtyping-ATRT/results/ATRT-molecular-subtypes.tsv ${commit_dir}

# Run compile subtyping
echo "Run compile subtyping"
cd ${analyses_dir}/molecular-subtyping-pathology
bash run-subtyping-aggregation.sh

# Copy over compiled subtyping
cp ${analyses_dir}/molecular-subtyping-pathology/results/*.tsv ${commit_dir}

# Run integrate subtyping
echo "Run integrate subtyping"
cd ${analyses_dir}/molecular-subtyping-integrate
bash run-subtyping-integrate.sh

# Copy over integrated subtyping
cp ${analyses_dir}/molecular-subtyping-integrate/results/histologies.tsv ${data_dir}
cp ${analyses_dir}/molecular-subtyping-integrate/results/*.tsv ${commit_dir}

# Create the independent sample list using the *FULL* histology file (i.e. - histologies.tsv)
echo "Create independent sample list"
cd ${analyses_dir}/independent-samples
bash run-independent-samples.sh

# Copy over independent specimen lists
cp ${analyses_dir}/independent-samples/results/independent-specimens.* ${commit_dir}

# Create an md5sum file for all the files in the directories where the analysis
# files are compiled
cd ${commit_dir}
# Remove old md5sum commit file if it exists
rm -f analysis_files_commit_md5sum.txt
# Create a new md5sum commit file
md5sum * > analysis_files_commit_md5sum.txt

# Upload all release and commit files s3 bucket in their respective folders
aws s3 cp ${commit_dir}/ $URL/$COMMIT/ --recursive

printf "\nDone generating pre-release files...\n\n"
