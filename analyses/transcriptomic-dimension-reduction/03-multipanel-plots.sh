# Bethell and Taroni for CCDL 2019
# This generates multipanel dimension reduction plots for RSEM and kallisto
# data, with points colored either by RNA library or broad histology
#
# Usage: bash 03-multipanel-plots.sh

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# loop over all RDS files that contain plot lists and save in the plots folder
FILES=plots/plot_data/*
for f in $FILES
do
  echo "Plotting $f ..."
  Rscript scripts/generate-multipanel-plot.R \
  --plot_rds $f \
  --plot_directory plots
done
