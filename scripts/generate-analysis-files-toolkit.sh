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

# Compile all the files that need to be included in the release in one place
# in the scratch directory
compiled_dir=${scratch_dir}/analysis_files_for_release
mkdir -p ${compiled_dir}

# Create the independent sample list using the *base* histology file (i.e. - histologies-base.tsv)
echo "Create independent sample list for fusion filtering module"
OPENPBTA_BASE_SUBTYPING=1 ../analyses/independent-samples/run-independent-samples.sh

# Fusion filtering
echo "Create fusion filtered list"
OPENPBTA_BASE_SUBTYPING=1 bash ${analyses_dir}/fusion_filtering/run_fusion_merged.sh

# Copy over fusions lists
cp ${analyses_dir}/fusion_filtering/results/fusion-putative-oncogenic.tsv ${compiled_dir}


# Run modules that cannot be run locally due to memory requirements
if [ "$RUN_LOCAL" -lt "1" ]; then
  
  # Run GISTIC step -- only the part that generates ZIP file
  echo "Run GISTIC"
  # Run a step that subs ploidy for NA to allow GISTIC to run
  Rscript ${analyses_dir}/run-gistic/scripts/prepare_seg_for_gistic.R \
  --in_consensus ${data_dir}/cnv-consensus.seg.gz \
  --out_consensus ${analyses_dir}/run-gistic/results/cnv-consensus-gistic-only.seg.gz \
  --histology ${data_dir}/histologies-base.tsv
  
  # This will use the file that just got generated above
  bash ${analyses_dir}/run-gistic/scripts/run-gistic-opentargets.sh
  
  # Copy over GISTIC
  cp ${analyses_dir}/run-gistic/results/cnv-consensus-gistic.zip ${compiled_dir}
  cp ${analyses_dir}/run-gistic/results/cnv-consensus-gistic-only.seg.gz ${compiled_dir}
  
  # Run step that generates "most focal CN" files (annotation) using the *BASE* histology file
  echo "Run focal CN file preparation"
  OPENPBTA_BASE_SUBTYPING=1 bash ${analyses_dir}/focal-cn-file-preparation/run-prepare-cn-OpenTarget.sh
  
  # Copy over focal CN
  cp ${analyses_dir}/focal-cn-file-preparation/results/consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz ${compiled_dir}
  cp ${analyses_dir}/focal-cn-file-preparation/results/consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz ${compiled_dir}
  cp ${analyses_dir}/focal-cn-file-preparation/results/consensus_wgs_plus_cnvkit_wxs.tsv.gz ${compiled_dir}

  # Move over the consensus with status file 
  cp ${scratch_dir}/focal-cn-file-preparation/results/consensus_seg_with_status.tsv ${compiled_dir}
  cp ${scratch_dir}/focal-cn-file-preparation/results/cnvkit_with_status.tsv ${compiled_dir}

fi

# Create an md5sum file for all the files in the directory where the analysis
# files are compiled
cd ${compiled_dir}
# Remove old file if it exists
rm -f analysis_files_toolkit_md5sum.txt
# Create a new md5sum.txt file
md5sum * > analysis_files_toolkit_md5sum.txt
