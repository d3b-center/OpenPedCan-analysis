#!/bin/bash

set -e
set -o pipefall


# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit


for jsonfile in /results/*.json ; 
do
    jq --compact-output '.[]' jsonfile > jsonfile.jsonl
done;



cat *.jsonl > all_comparisons.jsonl