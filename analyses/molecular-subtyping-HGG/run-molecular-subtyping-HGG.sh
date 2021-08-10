#!/bin/bash

# Chante Bethell for CCDL 2020
#
# Run the HGG molecular subtyping pipeline.
# Note: A local install of BEDOPS is required and can be installed using
# conda install -c bioconda bedops
# When OPENPBTA_SUBSET=1 (default), new HGG subset files will be generated.

set -e
set -o pipefail

# This option controls whether on not the step that generates the HGG only
# files gets run -- it will be turned off in CI
SUBSET=${OPENPBTA_SUBSET:-1}

# cds gencode bed file is used by other analyses where mutation data is
# filtered to only coding regions
exon_file="../../scratch/gencode.v27.primary_assembly.annotation.bed"

# Set the working directory to the directory of this file
cd "$(dirname "${BASH_SOURCE[0]}")"

# Gather pathology diagnosis and pathology free text diagnosis for HGG sample selection
Rscript 00-HGG-select-pathology-dx.R

# Run the first script in this module that reclassifies high-grade gliomas
Rscript --vanilla 01-HGG-molecular-subtyping-defining-lesions.R

# Run the second script in this module that subset files using the samples in the output
# file generated with `01-HGG-molecular-subtyping-defining-lesions.Rmd`.
if [ "$SUBSET" -gt "0" ]; then
  Rscript --vanilla 02-HGG-molecular-subtyping-subset-files.R
fi

#### Copy number data ----------------------------------------------------------

# Run the copy number data cleaning notebook
Rscript --vanilla 03-HGG-molecular-subtyping-cnv.R

#### Mutation data -------------------------------------------------------------

# if the cds gencode bed file is not available from another analysis, generate
# it here
if [ ! -f "$exon_file" ]; then
  gunzip -c "../../data/gencode.v27.primary_assembly.annotation.gtf.gz" \
    | awk '$3 ~ /CDS/' \
    | convert2bed --do-not-sort --input=gtf - \
    > $exon_file
fi

# Run notebook that cleans the mutation data
Rscript --vanilla 04-HGG-molecular-subtyping-mutation.R

#### Fusion data ---------------------------------------------------------------

# Run notebook that cleans the fusion data
Rscript --vanilla 05-HGG-molecular-subtyping-fusion.R

#### Gene expression data ------------------------------------------------------

# Run notebook that cleans the gene expression data
Rscript --vanilla 06-HGG-molecular-subtyping-gene-expression.R

#### Combine DNA data ----------------------------------------------------------

Rscript --vanilla 07-HGG-molecular-subtyping-combine-table.R

#### 1p/19q co-deleted oligodendrogliomas notebook -----------------------------

Rscript --vanilla 08-1p19q-codeleted-oligodendrogliomas.R

#### HGAT with `BRAF V600E` mutations clustering ------------------------------

# Run notebook that looks at how HGAT samples with `BRAF V600E` mutations cluster
Rscript --vanilla 09-HGG-with-braf-clustering.R

# Add TP53 annotation
Rscript --vanilla 10-HGG-TP53-annotation.Rmd',clean=TRUE)"
