#!/bin/bash
# OPenPedCan 2021
# Eric Wafula
set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# Set up paths to input and output directories for the analysis
absolute_path=$(cd "$(dirname "$0")"; pwd -P)
data_path="${absolute_path}/data"
metadata_path="metadata"
results_path="results"


######################### Process TARGET `Normal` samples for Illumina 450k arrays #########################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/Normal \
  --metadata_file ${metadata_path}/TARGET_Normal_MethylationArray_20160812.sdrf.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

######################### Process `NBL` samples for Illumina 450k arrays ############################
# process first batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/NBL \
  --metadata_file ${metadata_path}/TARGET_NBL_MethylationArray_20160812.sdrf.1.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/NBL-beta-values-methylation.tsv \
  ${results_path}/NBL-beta-values-methylation.1.tsv
mv ${results_path}/NBL-m-values-methylation.tsv \
  ${results_path}/NBL-m-values-methylation.1.tsv

# process second batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/NBL \
  --metadata_file ${metadata_path}/TARGET_NBL_MethylationArray_20160812.sdrf.2.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/NBL-beta-values-methylation.tsv \
  ${results_path}/NBL-beta-values-methylation.2.tsv
mv ${results_path}/NBL-m-values-methylation.tsv \
  ${results_path}/NBL-m-values-methylation.2.tsv

# merge first and second batches
echo "Merging batches..."
awk 'FNR==1 && NR!=1 {(/^<header>/) getline;} 1 {print}' \
  ${results_path}/NBL-beta-values-methylation.*.tsv \
  > ${results_path}/NBL-beta-values-methylation.tsv

awk 'FNR==1 && NR!=1 {(/^<header>/) getline;} 1 {print}' \
  ${results_path}/NBL-m-values-methylation.*.tsv \
  > ${results_path}/NBL-m-values-methylation.tsv

# remove intermediate files
rm ${results_path}/NBL-*-values-methylation.*.tsv

######################### Process `CCSK` samples for Illumina 450k arrays ############################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/CCSK \
  --metadata_file ${metadata_path}/TARGET_CCSK_MethylationArray_20160819.sdrf.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

######################### Process `OS` samples for Illumina 450k arrays ##############################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/OS \
  --metadata_file ${metadata_path}/TARGET_OS_MethylationArray_20161103.sdrf.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

######################### Process `WT` samples for Illumina 450k arrays ##############################
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/WT \
  --metadata_file ${metadata_path}/TARGET_WT_MethylationArray_20160831.sdrf.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

######################### Process `AML` samples for Illumina 450k arrays #############################
# process first batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/AML450k \
  --metadata_file ${metadata_path}/TARGET_AML_MethylationArray_20160812_450k.sdrf.1.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/AML450k-beta-values-methylation.tsv \
  ${results_path}/AML450k-beta-values-methylation.1.tsv
mv ${results_path}/AML450k-m-values-methylation.tsv \
  ${results_path}/AML450k-m-values-methylation.1.tsv

# process second batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/AML450k \
  --metadata_file ${metadata_path}/TARGET_AML_MethylationArray_20160812_450k.sdrf.2.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/AML450k-beta-values-methylation.tsv \
  ${results_path}/AML450k-beta-values-methylation.2.tsv
mv ${results_path}/AML450k-m-values-methylation.tsv \
  ${results_path}/AML450k-m-values-methylation.2.tsv

# merge first and second batches
echo "Merging batches..."
awk 'FNR==1 && NR!=1 {(/^<header>/) getline;} 1 {print}' \
  ${results_path}/AML450k-beta-values-methylation.*.tsv \
  > ${results_path}/AML450k-beta-values-methylation.tsv

awk 'FNR==1 && NR!=1 {(/^<header>/) getline;} 1 {print}' \
  ${results_path}/AML450k-m-values-methylation.*.tsv \
  > ${results_path}/AML450k-m-values-methylation.tsv

# remove intermediate files
rm ${results_path}/AML450k-*-values-methylation.*.tsv

######################### Process `AML` samples for Illumina 27k arrays ##############################
# process first batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/AML27k \
  --metadata_file ${metadata_path}/TARGET_AML_MethylationArray_20160812_27k.sdrf.1.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/AML27k-beta-values-methylation.tsv \
  ${results_path}/AML27k-beta-values-methylation.1.tsv
mv ${results_path}/AML27k-m-values-methylation.tsv \
  ${results_path}/AML27k-m-values-methylation.1.tsv

# process second batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/AML27k \
  --metadata_file ${metadata_path}/TARGET_AML_MethylationArray_20160812_27k.sdrf.2.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/AML27k-beta-values-methylation.tsv \
  ${results_path}/AML27k-beta-values-methylation.2.tsv
mv ${results_path}/AML27k-m-values-methylation.tsv \
  ${results_path}/AML27k-m-values-methylation.2.tsv

# process third batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/AML27k \
  --metadata_file ${metadata_path}/TARGET_AML_MethylationArray_20160812_27k.sdrf.3.txt \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/AML27k-beta-values-methylation.tsv \
  ${results_path}/AML27k-beta-values-methylation.3.tsv
mv ${results_path}/AML27k-m-values-methylation.tsv \
  ${results_path}/AML27k-m-values-methylation.3.tsv

# merge first, second and third batches
echo "Merging batches..."
awk 'FNR==1 && NR!=1 {(/^<header>/) getline;} 1 {print}' \
  ${results_path}/AML27k-beta-values-methylation.*.tsv \
  > ${results_path}/AML27k-beta-values-methylation.tsv

awk 'FNR==1 && NR!=1 {(/^<header>/) getline;} 1 {print}' \
  ${results_path}/AML27k-m-values-methylation.*.tsv \
  > ${results_path}/AML27k-m-values-methylation.tsv

# remove intermediate files
rm ${results_path}/AML27k-*-values-methylation.*.tsv

######################### Process `CBTN` samples for Illumina 850k arrays ############################
# process first batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/CBTN \
  --metadata_file ${metadata_path}/manifest_methylation_CBTN_20220410.1.csv \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/CBTN-beta-values-methylation.tsv \
  ${results_path}/CBTN-beta-values-methylation.1.tsv
mv ${results_path}/CBTN-m-values-methylation.tsv \
  ${results_path}/CBTN-m-values-methylation.1.tsv

# process second batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/CBTN \
  --metadata_file ${metadata_path}/manifest_methylation_CBTN_20220410.2.csv \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/CBTN-beta-values-methylation.tsv \
  ${results_path}/CBTN-beta-values-methylation.2.tsv
mv ${results_path}/CBTN-m-values-methylation.tsv \
  ${results_path}/CBTN-m-values-methylation.2.tsv

# process third batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/CBTN \
  --metadata_file ${metadata_path}/manifest_methylation_CBTN_20220410.3.csv \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/CBTN-beta-values-methylation.tsv \
  ${results_path}/CBTN-beta-values-methylation.3.tsv
mv ${results_path}/CBTN-m-values-methylation.tsv \
  ${results_path}/CBTN-m-values-methylation.3.tsv

# process fourth batch
Rscript --vanilla 01-preprocess-illumina-arrays.R \
  --base_dir ${data_path}/CBTN \
  --metadata_file ${metadata_path}/manifest_methylation_CBTN_20220410.4.csv \
  --preprocess_method preprocessQuantile \
  --snp_filter

mv ${results_path}/CBTN-beta-values-methylation.tsv \
  ${results_path}/CBTN-beta-values-methylation.4.tsv
mv ${results_path}/CBTN-m-values-methylation.tsv \
  ${results_path}/CBTN-m-values-methylation.4.tsv

# merge first, second, third, and third batches
echo "Merging batches..."
awk 'FNR==1 && NR!=1 {(/^<header>/) getline;} 1 {print}' \
  ${results_path}/CBTN-beta-values-methylation.*.tsv \
  > ${results_path}/CBTN-beta-values-methylation.tsv

awk 'FNR==1 && NR!=1 {(/^<header>/) getline;} 1 {print}' \
  ${results_path}/CBTN-m-values-methylation.*.tsv \
  > ${results_path}/CBTN-m-values-methylation.tsv

# remove intermediate files
rm ${results_path}/CBTN-*-values-methylation.*.tsv

################################## Compressing methylations results #####################################
echo "Compressing processed methylations result files..."
gzip -v ${results_path}/*values-methylation.tsv

echo "Analysis Done..."
