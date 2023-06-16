#!/bin/sh

set -e
set -o pipefail

printf "Start molecular subtyping...\n\n"

# Set locations for s3 bucket that contains release file
URL="s3://d3b-openaccess-us-east-1-prd-pbta/open-targets"
RELEASE="v12"

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# Get base directory of project
cd ..
BASEDIR="$(pwd)"
cd -
  
analyses_dir="$BASEDIR/analyses"
data_dir="$BASEDIR/data/$RELEASE"
scratch_dir="$BASEDIR/scratch"

# Compile all the files that need to be included in the release in one place
# in the scratch directory
release_dir="${scratch_dir}/analysis-files-pre-release"
mkdir -p ${release_dir}

## Run subtyping modules

# Run MB subtyping
echo "Run MB subtyping"
cd ${analyses_dir}/molecular-subtyping-MB
bash run-molecular-subtyping-mb.sh

# Run CRANIO subtyping
echo "Run CRANIO subtyping"
cd ${analyses_dir}/molecular-subtyping-CRANIO
bash run-molecular-subtyping-cranio.sh

# Run EPN subtyping
echo "Run EPN subtyping"
cd ${analyses_dir}/molecular-subtyping-EPN
bash run-molecular-subtyping-EPN.sh

# Run Embryonal subtyping
echo "Run Embryonal subtyping"
cd ${analyses_dir}/molecular-subtyping-embryonal
bash run-embryonal-subtyping.sh

# Run chordoma subtyping
echo "Run chordoma subtyping"
cd ${analyses_dir}/molecular-subtyping-chordoma
bash run-molecular-subtyping-chordoma.sh

# Run EWS subtyping
echo "Run EWS subtyping"
cd ${analyses_dir}/molecular-subtyping-EWS
bash run_subtyping.sh

# Run neurocytoma subtyping
echo "Run neurocytoma subtyping"
cd ${analyses_dir}/molecular-subtyping-neurocytoma
bash run_subtyping.sh

# Run HGG subtyping
echo "Run HGG subtyping"
cd ${analyses_dir}/molecular-subtyping-HGG
bash run-molecular-subtyping-HGG.sh

# Run LGAT subtyping
echo "Run LGAT subtyping"
cd ${analyses_dir}/molecular-subtyping-LGAT
bash run_subtyping.sh

# Run NBL subtyping
echo "Run NBL subtyping"
cd ${analyses_dir}/molecular-subtyping-NBL
bash run-molecular-subtyping-NBL.sh

# Run ATRT subtyping
echo "Run ATRT subtyping"
cd ${analyses_dir}/molecular-subtyping-ATRT
bash run-molecular-subtyping-ATRT.sh

# Run compile subtyping
echo "Run compile subtyping"
cd ${analyses_dir}/molecular-subtyping-pathology
bash run-subtyping-aggregation.sh

# Run integrate subtyping
echo "Run integrate subtyping"
cd ${analyses_dir}/molecular-subtyping-integrate
bash run-subtyping-integrate.sh

# Copy over integrated subtyping - the *FULL* histology file
cp ${analyses_dir}/molecular-subtyping-integrate/results/histologies.tsv ${data_dir}
cp ${analyses_dir}/molecular-subtyping-integrate/results/histologies.tsv ${release_dir}

# Create the independent sample list using the *FULL* histology file (i.e. - histologies.tsv)
echo "Create independent sample list"
cd ${analyses_dir}/independent-samples
bash run-independent-samples.sh

# Copy over independent specimen lists
cp ${analyses_dir}/independent-samples/results/independent-specimens.* ${data_dir}
cp ${analyses_dir}/independent-samples/results/independent-specimens.* ${release_dir}


# Create an md5sum file for all the files in the directories where the analysis
# files are compiled
cd ${release_dir}
# Remove old md5sum release file if it exists
rm -f analysis_files_release_md5sum.txt
# Create a new md5sum release file
md5sum * > analysis_files_release_md5sum.txt

# Upload all release files s3 bucket in their respective folders
#aws s3 cp ${release_dir}/ $URL/$RELEASE/ --recursive

printf "\nDone running molecular subtyping...\n\n"
