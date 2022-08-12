#!/bin/bash

# K S Gaonkar

# This analysis applies the TP53 inactivation classifier  https://linkinghub.elsevier.com/retrieve/pii/S2211124718304376
# NF1 inactivation classifier https://bmcgenomics.biomedcentral.com/articles/10.1186/s12864-017-3519-7
# Predicts TP53 and NF1 inactivation score per polya and stranded RNAseq samples

# The script takes one environment variable, `OPENPBTA_BASE_SUBTYPING`, if value is 1 then
# uses histologies-base.tsv for subtyping if value is 0 runs all modules with histologies.tsv(Default)

set -e
set -o pipefail

# The script can tak three environment variables:
# `OPENPBTA_BASE_SUBTYPING`: 
#     if value is 1, then uses `pbta-histologies-base.tsv` for subtyping. 
#     if value is 0 (DEFAULT), runs module with `pbta-histologies.tsv`
# `OPENPEDCAN_POLYA_STRAND`: 
#     if value is 1 (DEFAULT), runs the POLYA_STRAND steps
#     if value is 0, skips the POLYA_STRAND steps

POLYA_STRAND=${OPENPEDCAN_POLYA_STRAND:-1}
RUN_FOR_SUBTYPING=${OPENPBTA_BASE_SUBTYPING:-0}

# This script should always run as if it were being called from
# the directory it lives in.
analysis_dir="$(perl -e 'use File::Basename;
  use Cwd "abs_path";
  print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$analysis_dir" || exit


data_dir="../../data"
scratch_dir="../../scratch"
# cds gencode bed file  
cds_file="${scratch_dir}/gencode.v27.primary_assembly.annotation.bed"
snvconsensus_file="${data_dir}/snv-consensus-plus-hotspots.maf.tsv.gz"
cnvconsensus_file="${data_dir}/consensus_wgs_plus_cnvkit_wxs.tsv.gz"
collapsed_rna_file="${data_dir}/gene-expression-rsem-tpm-collapsed.rds"

if [[ $RUN_FOR_SUBTYPING == "0" ]]
then
   histology_file="../../data/histologies.tsv" 
else 
   histology_file="../../data/histologies-base.tsv"  
fi


# Convert GTF to BED file
# Here we are only extracting lines with as a CDS i.e. are coded in protein
gunzip -c ${data_dir}/gencode.v27.primary_assembly.annotation.gtf.gz \
  | awk '$3 ~ /CDS/' \
  | convert2bed --do-not-sort --input=gtf - \
  > $cds_file

# Prep the SNV consensus data for evaluation downstream
Rscript --vanilla ${analysis_dir}/00-tp53-nf1-alterations.R \
  --snvConsensus ${snvconsensus_file} \
  --cnvConsensus ${cnvconsensus_file} \
  --histologyFile ${histology_file} \
  --outputFolder ${analysis_dir}/results \
  --cohort "PBTA","TARGET","GMKF" \
  --gencode ${cds_file} \
  --expr ${collapsed_rna_file}

# Define RNA library files, which result from the script above
collapsed_stranded="${scratch_dir}/gene-expression-rsem-tpm-collapsed-stranded.rds"
collapsed_polya="${scratch_dir}/gene-expression-rsem-tpm-collapsed-poly-A.rds"
collapsed_polya_stranded="${scratch_dir}/gene-expression-rsem-tpm-collapsed-poly-A-stranded.rds"
collapsed_exome_capture="${scratch_dir}/gene-expression-rsem-tpm-collapsed-exome_capture.rds"

# Run classifier and ROC plotting for RNA data - currently, we have 4 types of RNA libraries. 
# We should add to this if we get more types.
python3 ${analysis_dir}/01-apply-classifier.py -f ${collapsed_stranded}
python3 ${analysis_dir}/01-apply-classifier.py -f ${collapsed_polya}

# Skip poly-A stranded and exome capture steps in CI because too few samples
if [ "$POLYA_STRAND" -gt "0" ]; then
  python3 ${analysis_dir}/01-apply-classifier.py -f ${collapsed_polya_stranded}
  python3 ${analysis_dir}/01-apply-classifier.py -f ${collapsed_exome_capture}
fi

# check correlation expression and scores
Rscript -e "rmarkdown::render('${analysis_dir}/02-qc-rna_expression_score.Rmd',params=list(base_run = $RUN_FOR_SUBTYPING, ci_run = $POLYA_STRAND))"

# subset cnv where tp53 is lost
Rscript -e "rmarkdown::render('${analysis_dir}/03-tp53-cnv-loss-domain.Rmd',params=list(base_run = $RUN_FOR_SUBTYPING))"

# subset SV where tp53 is lost
Rscript -e "rmarkdown::render('${analysis_dir}/04-tp53-sv-loss.Rmd',params=list(base_run = $RUN_FOR_SUBTYPING))"

# gather TP53 altered status
Rscript -e "rmarkdown::render('${analysis_dir}/05-tp53-altered-annotation.Rmd',params=list(base_run = $RUN_FOR_SUBTYPING))"

# evaluate classifer scores for stranded data
python3 ${analysis_dir}/06-evaluate-classifier.py -s ${analysis_dir}/results/tp53_altered_status.tsv -f ${analysis_dir}/results/gene-expression-rsem-tpm-collapsed-stranded_classifier_scores.tsv -c ${histology_file} -o stranded

# Skip poly-A, poly-A stranded, exome capture steps in CI
if [ "$POLYA_STRAND" -gt "0" ]; then
  python3 ${analysis_dir}/06-evaluate-classifier.py -s ${analysis_dir}/results/tp53_altered_status.tsv -f ${analysis_dir}/results/gene-expression-rsem-tpm-collapsed-poly-A-stranded_classifier_scores.tsv -c ${histology_file} -o polya_stranded
  python3 ${analysis_dir}/06-evaluate-classifier.py -s ${analysis_dir}/results/tp53_altered_status.tsv -f ${analysis_dir}/results/gene-expression-rsem-tpm-collapsed-exome_capture_classifier_scores.tsv -c ${histology_file} -o exome_capture
  python3 ${analysis_dir}/06-evaluate-classifier.py -s ${analysis_dir}/results/tp53_altered_status.tsv -f ${analysis_dir}/results/gene-expression-rsem-tpm-collapsed-poly-A_classifier_scores.tsv -c ${histology_file} -o polya
fi
