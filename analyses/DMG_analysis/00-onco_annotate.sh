#!/bin/bash

set -e
set -o pipefail

python_path=(/usr/bin/python3)
maf_annotator=(/Users/gengz/Documents/GitHub/oncokb-annotator/MafAnnotator.py)
maf_in=(/Users/gengz/Documents/GitHub/OpenPedCan-analysis/analyses/DMG_analysis/subset/snv_selected_genes.maf.tsv)
maf_oncokb_out=(/Users/gengz/Documents/GitHub/OpenPedCan-analysis/analyses/DMG_analysis/subset/snv_selected_genes_oncokb.maf.tsv)

# Run maf_annotator on dgd samples
$python_path $maf_annotator -i $maf_in -o $maf_oncokb_out -b $ONCO_KB -q hgvsp_short -r GRCh38