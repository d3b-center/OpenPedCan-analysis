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

docker run \
       --env-file=open_pbta_envs.txt \
       --volume "$(pwd)":/rocker-build/ \
       -it "openpedcan-analysis:latest" "$@"
