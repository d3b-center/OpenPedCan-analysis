# Analysis of Mutational Signatures

This analysis evaluates mutational signatures of the [consensus SNV callers file](https://github.com/AlexsLemonade/OpenPBTA-analysis/tree/master/analyses/snv-callers#consensus-mutation-call).

The overall analysis considers two different approaches to assessing mutational signatures in OpenPedCan data:

+ Evaluate single- and double-base substitution signatures from [COSMIC signatures](https://cancer.sanger.ac.uk/cosmic)
and [Alexandrov et al, 2013](https://www.ncbi.nlm.nih.gov/pubmed/23945592) for all samples using [`deconstructSigs`](https://github.com/raerose01/deconstructSigs).

+ Evaluate known (adult) CNS signatures, as identified in [Degasperi et al, 2020](https://doi.org/10.1038/s43018-020-0027-5) in samples using  [`deconstructSigs`](https://github.com/raerose01/deconstructSigs)


## Usage

To run the mutational signature evaluations, use this in command line:
```
bash run_mutational_signatures.sh
```
_This assumes you are in the top directory of the repository._

The analysis scripts will return results for each caller in the `plots` and `results` folder.


## Contents

+ The Rmd `01-known_signatures.Rmd` runs single-base substitution (SBS) mutational signatures analyses using existing COSMIC and Alexander et al, 2013 signatures. 
  + Calculates weights from [`deconstructSigs::whichSignatures`](https://www.rdocumentation.org/packages/deconstructSigs/versions/1.8.0/topics/whichSignatures) which are are multiplied by each sample's sum of mutations as provided by [`deconstructSigs::mut.to.sigs.input`](https://www.rdocumentation.org/packages/deconstructSigs/versions/1.8.0/topics/mut.to.sigs.input).
  + These numbers are saved to the `_signatures_results.tsv` files in the `results` folder.
  
+ The Rmd `02-cosmic_dbs_signatures.Rmd` runs double-base substitution (DBS) mutational signature analyses using existing COSMIC v3.3.1 signatures, and calculates weights and saves results as is done in `01-known_signatures.Rmd`.
  
+ The script `03-fit_cns_signatures.R` determines the relative contributions of 8 known (adult) CNS signatures in the OpenPedCan data (considers _both_ WXS and WGS) using [`deconstructSigs::whichSignatures()`](https://github.com/raerose01/deconstructSigs).
  + This script saves the fitted CNS signature exposures in `results/fitted_exposures_signal-cns-deconstructSigs.RDS`

+ The Rmd `04-explore_hypermutators.Rmd` investigates whether hyper-mutant and/or ultra-hypermutant samples have enrichment of signatures 3, 18, and/or MMR.
  + We also asked whether these samples show dysregulated _TP53_.


## Summary of the calculations

### Number of mutations per signature

The weights from [`deconstructSigs::whichSignatures`](https://www.rdocumentation.org/packages/deconstructSigs/versions/1.8.0/topics/whichSignatures) are multiplied by each sample's sum of mutations as provided by [`deconstructSigs::mut.to.sigs.input`](https://www.rdocumentation.org/packages/deconstructSigs/versions/1.8.0/topics/mut.to.sigs.input).
These numbers are saved to the `_signatures_results.tsv` files in the `results` folder.

For more information, see the [`calc_mut_per_sig`]() code.

### Proportion of tumors with a signature

A tumor is considered to have a particular signature if its weight is non-zero.
This is divided by the number of tumor samples in that particular histology group.
For more information, see the [`bubble_matrix_plot`]() code.

## Overall file structure
```
OpenPedCan-analysis
├── analyses
│   └── mutational-signatures
│       ├── 01-known_signatures.Rmd
│       ├── 01-known_signatures.nb.html
|       ├── 02-cosmic_dbs_signatures.Rmd
|       ├── 02-cosmic_dbs_signatures.nb.html
|       ├── 03-fit_cns_signatures.R
|       ├── 04-explore_hypermutators.Rmd
|       ├── 04-explore_hypermutators.nb.html
│       ├── README.md
│       ├── Rplots.pdf
|       ├── input
|       │   ├── COSMIC_v3.3.1_SBS_GRCh38.txt
|       │   ├── COSMIC_v3.3_DBS_GRCh38.txt
│       ├── plots
│       │   ├── cns
│       │   │   └── tmb_signature_dotplot.pdf
│       │   ├── cosmicv2
│       │   │   ├── bubble_matrix_cosmic_mutation_sig.png
│       │   │   └── signature_grouped_barplots
|       |   |   |   ├──barplot_{HISTOLOGY_GROUP}_cosmic_mutation_sig.png
|       |   |   |   └──...   
│       │   ├── cosmicv3
│       │   │   ├── bubble_matrix_cosmic_mutation_sig.png
│       │   │   └── signature_grouped_barplots
|       |   |   |   ├──barplot_{HISTOLOGY_GROUP}_cosmic_mutation_sig.png
|       |   |   |   └──...  
│       │   └── cosmicv3_dbs
│       │   |   ├── bubble_matrix_nature_mutation_sig.png
│       │   |   └── signature_grouped_barplots
|       |   |   |   ├──barplot_{HISTOLOGY_GROUP}_cosmicv3_dbs_mutation_sig.png
|       |   |   |   └──...   
│       │   └── nature
│       │   |   ├── bubble_matrix_nature_mutation_sig.png
│       │   |   └── signature_grouped_barplots
|       |   |   |   ├──barplot_{HISTOLOGY_GROUP}_nature_mutation_sig.png
|       |   |   |   └──...   
|       ├── results
|       │   ├── COSMICv2_signature_exposures.tsv
|       │   ├── COSMICv3.3_DBS_signature_exposures.tsv
|       │   ├── COSMICv3.3_signature_exposures.tsv
|       │   ├── Nature_signature_exposures.tsv
|       │   ├── cosmicv2_signatures_results.tsv
|       │   ├── cosmicv3.3_dbs_signatures_results.tsv
|       │   ├── cosmicv3.3_signature_results.tsv
|       │   ├── deconstructSigs_cns_exposures_merged.tsv
|       │   ├── fitted_exposures_signal-cns_deconstructSigs.rds
|       │   ├── hypermutator_sig_matrix.tsv
|       │   ├── nature_signatures_results.tsv
|       │   └── sig_matrix_by_molecular_subtype.tsv
│       ├── scripts
│       │   └── de_novo_signature_extraction.R
│       └── util
│           └── mut_sig_functions.R
├── data
```

## Summary of custom functions

|Function Name|Summary|
|-------------|-----------|
|`sample_mut_sig_plot`|Saves traditional mutational signature plots for each sample|
|`calc_mut_per_sig`|Given `deconstructSigs::whichSignature` output, formats the sample data into a data.frame and calculates the mutations per Mb for each sample and each signature|
|`bubble_matrix_plot`|Groups together data by histology and makes the bubble matrix plot|
|`grouped_sig_barplot`|Creates signature grouped barplots for histology group provided and only uses primary tumors' data|
