# OpenPedCan Tumor Mutation Burden calculation

This analysis utilizes the SNV consensus MAF file, `../../data/snv-consensus-plus-hotspots.maf.tsv.gz` from [Pediatric Open Targets, OPenPedCan-analysis](https://github.com/PediatricOpenTargets/OpenPedCan-analysis) datasets generated using [Kids First DRC Consensus Calling Workflow](https://github.com/kids-first/kf-somatic-workflow/blob/master/docs/kfdrc-consensus-calling.md) to calculate Tumor Mutation Burden (TMB). 
TMB is calculated for tumor samples in each experimental strategy (WGS and WXS) using SNV calls for all cohorts and cancer types evaluated in the project. 
The TMB calculation is adapted from [snv-callers module](https://github.com/AlexsLemonade/OpenPBTA-analysis/tree/master/analyses/snv-callers) of the OpenPBTA-analyses, but uses nucleotide variants (SNVs) in the consensus file called in at least 2 of the 4 caller (Mutect2, Strelka2, Lancet, and Vardict) utilized in the consensus calling workflow and/or 1 of the 4 callers if the SNV was a hotspot mutation. 
The SNV consensus is split into two subsets of SNVs and multinucleotide variants (MNVs). 
The MNVs subset is split into SNVs, merged to the SNVs subset, and sample-specific redundant calls removed. 
The resulting merged and non-redundant SNV consensus calls togther with sample-specific BED files are utilized for TMB calculation as described below. 


## TMB Calculation

For each experimental strategy and TMB calculation, the intersection of the genomic regions effectively being surveyed are used. 
All calls in the consensus file are used for TMB calculations. 
These genomic regions are used to first filter mutations to these regions and then the size in bp of the effectively surveyed genomic regions is used as the TMB denominator.

### All mutations TMB

For all mutation TMBs, consensus calls are used. 
For WGS samples, the size of the genome covered by the intersection of Strelka2 and Mutect2's surveyed areas which are considered representative of all callers is used for the denominator.

```
WGS_all_mutations_TMB = (total # mutations in consensus MAF) / intersection_strelka_mutect_genome_size
```
For WXS samples, the size of the genome for each the WXS bed region file is used for the denominator with the associated tumor samples.
```
WXS_all_mutations_TMB = (total # mutations in consensus MAF)) / wxs_genome_size
```
### Coding only TMB

Coding only TMB uses all callers as well and the intersection demoninators are calculated by using coding sequence ranges in the gtf from Gencode 39.
This file is included in the OpenPedCan data download.
SNVs outside of these coding sequences are filtered out before being summed and used for TMB calculations as follows:

```
WGS_coding_only_TMB = (total # coding mutations in consensus MAF) / intersection_wgs_strelka_mutect_CDS_genome_size
```
For WXS samples, each the WXS bed region file is intersected with the coding sequences for filtering and for determining the denominator to be used with the with the associated tumor samples.
```
WXS_coding_only_TMB = (total # coding mutations in consensus MAF) / intersection_wxs_CDS_genome_size
```

## General usage of scripts


#### `run_tmb_calculation.sh`
This is a bash script wrapper for setting input file paths for the main anlysis script, `01-calculate_tmb.R` and creating additional intermedaite input files `../../scratch/intersect_strelka_mutect2_vardict_WGS.bed` and `gencode.v39.primary_assembly.annotation.bed`. All file paths set in this script relative to the module directory. Therefore, this script should always run as if it were being called from the directory it lives in, the module directory (`OpenPedCan-analysis/analyses/tmb-calculation`).


#### 01-calculate_tmb.R
Uses the OpenPedCan SNV consensus file to calculate TMB for all WGS and WXS samples. 
Two TMB files are created, one including *all SNVs* and a *coding SNVs only*, both utilizing the consensus MAF.

**Argument descriptions**
```
 --consensus_maf_file : Input OpenPedCan SNV consensus MAF file.

 --bed_files : Input samples to target BED mapping file.

 --histologies_file : Input OpenPedCan histologies metadata file.

 --coding_regions : BED file for coding regions to use for coding only TMB.

 --nonsynfilter_maf : If TRUE, filter out synonymous mutations, keep
                 non-synonymous mutations, according to maftools definition.
                 Default is FALSE

 --nonsynfilter_focr : If TRUE, filter out synonymous mutations, keep non-synonymous
                 mutations, according to Friends of Cancer esearch definition.
                 Default is FALSE
```

#### `Util/split_mnv.R`
Contains a function to split multinucleotide variants (MNVs) into single nucleotide variants (SNVs).

#### `Util/tmb_functions.R`
Contains functions for calculating Tumor Mutation Burden (TMB).


## Analysis input file

### OpenPedCan data download files:
- `../../data/snv-consensus-plus-hotspots.maf.tsv.gz`
- `../../data/gencode.v39.primary_assembly.annotation.gtf.gz`
- `../../data/histologies-base.tsv`

### Module specific input files:
- `../../data/v12/20038D-17Q6-01.regions.100bp_padded.bed`
- `../../data/v12/S0274956_Padded_HG38.merged.bed`
- `../../data/v12/S02972011_Covered_hg38_100.bed`
- `../../data/v12/S04380110_Regions_hg38_100.bed`
- `../../data/v12/S07604715_100bp_Padded.bed`
- `../../data/v12/SeqCap_EZ_Exome_v2_Padded_HG38.merged.bed`
- `../../data/v12/StrexomeLite_hg38_liftover_100bp_padded.bed`
- `../../data/v12/Strexome_targets_intersect_sorted_padded100.GRCh38.bed`
- `../../data/v12/TARGET_AML_NBL_WT_SeqVal79_attempt06_AllTracks_HG38_bed_expanded100.bed`
- `../../data/v12/WGS.hg38.lancet.300bp_padded.bed`
- `../../data/v12/WGS.hg38.lancet.unpadded.bed`
- `../../data/v12/WGS.hg38.mutect2.vardict.unpadded.bed`
- `../../data/v12/WGS.hg38.strelka2.unpadded.bed`
- `../../data/v12/WGS.hg38.vardict.100bp_padded.bed`
- `../../data/v12/agilent-v4-targets-ucsc.100bp_padded.bed`
- `../../data/v12/ashion_exome_v2_targets_hg38_padded100.bed`
- `../../data/v12/hg38_strelka.bed`
- `../../data/v12/intersect_cds_lancet_strelka_mutect_WGS.bed`
- `../../data/v12/intersect_strelka_mutect_WGS.bed`
- `../../data/v12/nexterarapidcapture_exome_targetedregions_v1.2_hg38_100.bed`
- `../../data/v12/onco1500-v2-targets-ucsc.100bp_padded.bed`
- `../../data/v12/onco1500-v4-targets-ucsc.100bp_padded.bed`
- `../../data/v12/onco1500-v6-targets-ucsc.100bp_padded.bed`
- `../../data/v12/onco1500-v6a-targets-ucsc.100bp_padded.bed`
- `../../data/v12/truseq-exome-targeted-regions-manifest-v1-2_hg38_100.bed`
- `../../data/v12/wgs_canonical_calling_regions.hg38.bed`
- `../../data/v12/xgen-exome-research-panel-targets_hg38_ucsc_liftover.100bp_padded.sort.merged.bed`


## Analysis result files

### Output:
- `results/snv-mutation-tmb-coding.tsv`
- `results/snv-mutation-tmb-all.tsv`
