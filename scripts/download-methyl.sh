#!/bin/bash

set -e
set -o pipefail

# download methylation files from the OpenPedCan data v13 data release s3 bucket

URL="https://d3b-openaccess-us-east-1-prd-pbta.s3.amazonaws.com/open-targets"
RELEASE="v13"

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

# check if the release folder exists, if not, create a release folder
[ ! -d "$BASEDIR/data/$RELEASE/" ] && mkdir $BASEDIR/data/$RELEASE/

# The md5sum file provides our single point of truth for which files are in a release.
curl --create-dirs $URL/$RELEASE/methyl-md5sum.txt -o $BASEDIR/data/$RELEASE/methyl-md5sum.txt -z $BASEDIR/data/$RELEASE/methyl-md5sum.txt

FILES=(`tr -s ' ' < $BASEDIR/data/$RELEASE/methyl-md5sum.txt | cut -d ' ' -f 2` release-notes.md)

for file in "${FILES[@]}"
do
  if [ ! -e "$BASEDIR/data/$RELEASE/$file" ]
  then
    echo "Downloading $file"
    curl --create-dirs $URL/$RELEASE/$file -o $BASEDIR/data/$RELEASE/$file
  fi
done

#check md5sum
cd $BASEDIR/data/$RELEASE
echo "Checking MD5 hashes..."
md5sum -c methyl-md5sum.txt
cd $BASEDIR

# Make symlinks in data/ to the files in the just downloaded release folder.
for file in "${FILES[@]}"
do
  ln -sfn $RELEASE/$file data/$file
done
