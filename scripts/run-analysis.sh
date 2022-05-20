#!/bin/bash

error() {
  echo "$@" 1>&2
}

fail() {
  error "$@"
  exit 1
}

script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# However in order to give Docker access to all the code we have to
# move up a level
cd ..

env | grep "OPENPBTA_.*" > open_pbta_envs.txt

OPENPBTA_URL=https://s3.amazonaws.com/d3b-openaccess-us-east-1-prd-pbta/data 
OPENPBTA_RELEASE=testing bash download-data.sh
OPENPBTA_ALL=0 bash analyses/interaction-plots/01-create-interaction-plots.sh
bash analyses/telomerase-activity-prediction/RUN-telomerase-activity-prediction.sh
