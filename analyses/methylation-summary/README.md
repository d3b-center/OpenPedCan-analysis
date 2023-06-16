# OpenPedCan Methylation Summary

## Purpose

Summarize preprocessed `Illumina Infinium Human Methylation` array measurements produced by the [OpenPedCan methylation-preprocessing module](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/methylation-preprocessing) and [Illumina infinium methylation array CpG probe coordinates](https://support.illumina.com/array/array_kits/infinium-methylationepic-beadchip-kit/downloads.html) lifted-over from `GRCh37` to `GRCh38` build and annotated with [GENCODE v39 release](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_39/) that is currently utilized in the OpenPedCan data analyses.

## Methylation array CpG probe coordinates liftover
The 450K and EPIC Illumina Infinium methylation array CpG probe coordinates are based on the `Human Build 37 (GRCh37/hg19)` genome assembly. Probe coordinates were converted to `Human Build 38 (GRCh38/hg38)` using the [ENSEMBL Assembly Converter tool](https://useast.ensembl.org/Homo_sapiens/Tools/AssemblyConverter). A probe annotation file, `infinium.gencode.v39.probe.annotations.tsv` currently used in the module analyses, was created by annotating all the probes that were lifted over with associated gene features (i.e., `promoter`, `5' UTR`, `exon`, `intron`, `3'UTR`, and `intergenic`) based on `GENCODE v39` release. Intron coordinates, typically not included in the GFF3/GTF genome annotation formats, were added to the GENCODE annotations file using [GenomeTools](http://genometools.org/). Probe locations were then assigned with their intersecting gene annotation features with [bedtools](https://bedtools.readthedocs.io/en/latest/content/bedtools-suite.html). 


## Analysis scripts
1. **`01-calculate-tpm-medians.R`** script calculates representative cancer group gene-level and isoform-level TPM expression medians for subjects with both RNA-Seq and methylation data in a cohort.

```
Usage: Rscript --vanilla 01-calculate-tpm-medians.R [options]

Options:
  --histologies=CHARACTER
    Histologies file

  --rnaseq_matrix=CHARACTER
    OpenPedCan rnaseq tpm gene or isoform matrix file

 --methyl_probe_annot=CHARACTER
    Methyl gencode array probe annotations

  --methyl_independent_samples=CHARACTER
    OpenPedCan methyl independent biospecimen list file

  --methyl_independent_samples=CHARACTER
    OpenPedCan rnaseq independent biospecimen list file

  --exp_values_values=CHARACTER
    OpenPedCan expression matrix values: gene (default) and isoform

  -h, --help
    Show this help message and exit
```

2. **`02-calculate-methly-quantiles.R`** script calculates probe-level quantiles for either Beta-values or M-values methylation matrix.
```
Usage: Rscript --vanilla 02-calculate-methly-quantiles.R [options]

Options:
	--histologies=CHARACTER
		Histologies file

	--methyl_matrix=CHARACTER
		OPenPedCan methyl beta-values or m-values matrix file

 --methyl_probe_annot=CHARACTER
    Methyl gencode array probe annotations

	--independent_samples=CHARACTER
		OpenPedCan methyl independent biospecimen list file

	--methyl_values=CHARACTER
		OPenPedCan methly matrix values: beta (default) and m

	-h, --help
		Show this help message and exit
```

3. **`03-methyl-tpm-correlation.py`** script calculates representative `array probe` to `gene locus` correlations and `array probe` to `gene locus-isoforms` correlations between `RNA-Seq TPM-values` and either`Beta-values` or `M-values` for each cancer group within a cohort for patients who have both datasets.

```
usage: python3 03-methyl-tpm-correlation.py [-h] [-m {beta,m}] [-e {gene,isoform}] 
            [-v] HISTOLOGY_FILE RNA_INDEPENDENT_SAMPLES METHYL_INDEPENDENT_SAMPLES 
            METHLY_MATRIX EXP_MATRIX PROBE_ANNOT

positional arguments:
  HISTOLOGY_FILE        OPenPedCan histologies file
                        
  RNA_INDEPENDENT_SAMPLES
                        OPenPedCan rnaseq independent biospecimen list file
                        
  METHYL_INDEPENDENT_SAMPLES
                        OPenPedCan methyl independent biospecimen list file
                        
  METHLY_MATRIX         OpenPedCan methyl beta-values or m-values matrix file
                        
  EXP_MATRIX            OPenPedCan expression matrix file
                        
  PROBE_ANNOT           Methyl gencode array probe annotations
                        
optional arguments:
  -h, --help            show this help message and exit
  -m {beta,m}, --methyl_values {beta,m}
                        OpenPedCan methly matrix values: beta (default) and m
                        
  -e {gene,isoform}, --exp_values {gene,isoform}
                        OpenPedCan expression matrix values: gene (default) and isoform
                        
  -v, --version         Print the current 03-methyl-tpm-correlation.py version and exit
```

4. **`04-tpm-transcript-representation.py`** script Calculate rna-seq expression (tpm) gene isoform (transcript) representation for patients who have samples in both rna-seq and methylation datasets as follows:
  
  a) First calculate a Z score for each sample

  **Z<sub>s</sub>= S<sub>G_TPM</sub> - µ<sub>G_TPM</sub>/sd<sub>G_TPM</sub>**

  Where Z<sub>s</sub> is the Sample gene expression Z Score, S<sub>G_TPM</sub> is the gene expression value of that sample in TPM, µ<sub>G_TPM</sub> is the mean TPM expression of the gene in that cancer group, and sd<sub>G_TPM</sub> is the standard deviation of the TPM expression of the gene in that cancer group.

  b) Then Calculate the Weight. The inverse exponential function of the absolute Z-score will give us a weight that decreases the further the sample's gene expression deviates from the mean. This way, weird outliers will not distort the calculation.

  **W<sub>s</sub> = 1/e<sup>|Z<sub>s</sub>|</sup>**

  Where W<sub>s</sub> is the weight assigned to the sample, and Z<sub>s</sub> is the sample's gene expression Z score calculated in the previous step.

  c) Finally, apply the weights to the Transcript expressions and sum them to calculate the percent expression.

  **Transcript_Representation = (∑ W<sub>s</sub>•TPM<sub>S_transcript</sub>)/ (∑ W<sub>s</sub>• TPM<sub>S_Total(All transcripts)</sub>)**

  Where W<sub>s</sub> is the weight assigned to the sample calculated in the previous step, TPM<sub>S_transcript</sub> is expression of each Sample's individual transcript in TPM, and TPM<sub>S_Total(All transcripts)</sub> is the total expression in TPM  of transcripts of that gene in that sample.

```
usage: python3 04-tpm-transcript-representation.py [-h] [-m {beta,m}] [-e {gene,isoform}] 
            [-v] HISTOLOGY_FILE RNA_INDEPENDENT_SAMPLES METHYL_INDEPENDENT_SAMPLES 
            GENE_EXP_MATRIX ISOFORM_EXP_MATRIX PROBE_ANNOT

positional arguments:
  HISTOLOGY_FILE        OPenPedCan histologies file
                        
  RNA_INDEPENDENT_SAMPLES
                        OPenPedCan rnaseq independent biospecimen list file
                        
  METHYL_INDEPENDENT_SAMPLES
                        OPenPedCan methyl independent biospecimen list file
                        
  GENE_EXP_MATRIX       OPenPedCan gene expression matrix file
                        
  ISOFORM_EXP_MATRIX    OPenPedCan isoform expression matrix file
                        
  PROBE_ANNOT           Methyl gencode array probe annotations
                        
  -v, --version         Print the current 04-tpm-transcript-representation.py version and exit
```

5. **`05-create-methyl-summary-table.R`** script summarizes `array probe quantiles`, `Beta/M-values correlations` and `gene annotations` into gene locus and gene locus-isoforms methylation summary tables. The OPenPedCan API utilizes the summary tables to dynamically generate methylation plots displayed on the NCI MTP portal with the following columns:
    - **Gene_Symbol**: gene symbol
    - **targetFromSourceId**: Ensemble locus ID
    - **transcript_id**: Ensemble locus-isoform ID (for isoform-level summary table only)
    - **Gene_Feature**: GENCODE gene feature i.e., promoter, 5' UTR, exon, intron, 3'UTR, and intergenic
    - **Dataset**: OpenPedCan `cohort` i.e., TARGET
    - **Disease**: OpenPedCan `cancer_group` i.e., Neuroblastoma
    - **diseaseFromSourceMappedId**: EFO ID of OpenPedCan `cancer_group`
    - **MONDO**: MONDO_ID of OpenPedCan `cancer_group`
    - **Median_TPM**: representative `cancer_group` gene-level or isoform-level TPM expression medians in a `cohort`
    - **RNA_Correlation**: array probe-level correlation between `methylation Beta-values` and `RNA-Seq TPM values`
    - **Transcript_Representation**: RNA-Seq expression (tpm) percent transcript representation (for isoform-level summary table only)
    - **Probe_ID**: `Illumina Infinium HumanMethylation` array probe ID for the CpG site
    - **Chromosome**: chromosome for CpG site eg. chr1
    - **Location**: genomic location of the CpG site
    - **Beta_Q1**: array probe-level Beta Q1 quantile
    - **Beta_Q2**: array probe-level Beta Q2 quantile
    - **Beta_Median**: array probe-level Beta Q3 quantile
    - **Beta_Q4**: array probe-level Beta Q4 quantile
    - **Beta_Q5**: array probe-level Beta Q5 quantile
    - **datatypeId**: pediatric_cancer
    - **chop_uuid**: generate UUID
    - **datasourceId**: chop_gene_level_methylation or chop_isoform_level_methylation
```
Usage: 05-create-methyl-summary-table.R [options]

Options:
	--methyl_tpm_corr=CHARACTER
		Methyl beta/m-vlaues to tpm-values correlations results file

	--methyl_probe_qtiles=CHARACTER
		Methyl array probe beta/m-values quantiles results file

	--methyl_probe_annot=CHARACTER
		Methyl gencode array probe annotations

  --rnaseq_tpm_medians=CHARACTER
    RNA-Seq gene-level or isoform-level tmp median expression results file

  --tpm_transcript_rep=CHARACTER
    RNA-Seq expression (tpm) gene isoform (transcript) representation results file

	--efo_mondo_annot=CHARACTER
		OpenPedCan EFO and MONDO annotation file

	--exp_values=CHARACTER
		OpenPedCan expression matrix values:gene (default) and isoform

	--methyl_values=CHARACTER
		OpenPedCan methly matrix values: beta (default) and m



	-h, --help
		Show this help message and exit
```

6. **`06-methly-summary-tsv2jsonl.py `** script transforms tab-delimited methylation summary tables to JSONL (JSON-Line) format required for usage on the NCI MTP portal.
```
usage: python3 06-methly-summary-tsv2jsonl.py [-h] [-m {beta,m}] [-v] 
            GENE_SUMMARY_FILE ISOFORM_SUMMARY_FILE

positional arguments:
  GENE_SUMMARY_FILE     Gene-level methyl summary TSV file
                        
  ISOFORM_SUMMARY_FILE  Isoform-level methyl summary TSV file
                        
optional arguments:
  -h, --help            show this help message and exit
  -m {beta,m}, --methyl_values {beta,m}
                        OpenPedCan methly matrix values: beta (default) and m
                        
  -v, --version         Print the current 06-methly-summary-tsv2jsonl.py version and exit
```



## General usage of scripts
1. `run-methylation-summary.sh` is a wrapper bash script for execruing all the other analysis scripts in the module. All file paths set in this script relative to the module directory. Therefore, this script should always run as if it were being called from the directory it lives in, the module directory (`OpenPedCan-analysis/analyses/methylation-summary`).
```
bash run-methylation-summary.sh
```
2. Analyses involving 850k arrays with large number of samples representing OPenPedCan cancer groups (as in the CBTN cohort) will utlize of memory to run successfully.Where possible we utlized `Rsqlite3` to reduce memory footprint. 
3. In some computers the computer system `/tmp` is too small to hold temporary files generated during analysis by R scripts. Users are advised to create a `./tmp` in the module directory then execute R script by prepending with TMP/TMPDIR environmental variable as illustrated in the wrapper module bash script, `run-methy-summary.sh`.


## Input datasets
The methylation `beta-values` and `M-values`matrices are available on the CHOP HPC `Isilon` sever (location: `/mnt/isilon/opentargets/wafulae/methylation-preprocessing/results/`). Please contact `Avin Farrel (@afarrel)` for access if not already available for download using the [OpenPedCan data release download script](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/blob/dev/download-data.sh). 
- `../../data/infinium.gencode.v39.probe.annotations.tsv.gz`
- `../../data/independent-specimens.rnaseqpanel.eachcohort.tsv`
- `../../data/independent-specimens.methyl.eachcohort.tsv`
- `../../data/gene-expression-rsem-tpm-collapsed.rds`
- `../../data/rna-isoform-expression-rsem-tpm.rds`
- `../../data/methyl-beta-values.rds` 
- `../../data/efo-mondo-map.tsv`
- `../../data/histologies.tsv` 

## Output datasets
Most analysis result files sizes exceed the limit allowable to push on to a GitHub repository. All results files are available on the CHOP HPC `Isilon` sever (location: `/mnt/isilon/opentargets/wafulae/methylation-summary/results/`). Please contact `Avin Ferrel (@afarrel)` for access.
- `results/methyl-probe-annotations.tsv.gz`
- `results/methyl-probe-beta-quantiles.tsv.gz`
- `results/gene-methyl-probe-beta-tpm-correlations.tsv.gz`
- `results/isoform-methyl-probe-beta-tpm-correlations.tsv.gz`
- `results/gene-median-tpm-expression.tsv.gz`
- `results/isoform-median-tpm-expression.tsv.gz`
- `results/methyl-tpm-transcript-representation.tsv.gz`
- `results/gene-methyl-beta-values-summary.rds` 
- `results/gene-methyl-beta-values-summary.tsv.gz` 
- `results/gene-methyl-beta-values-summary.jsonl.gz`
- `results/isoform-methyl-beta-values-summary.rds` 
- `results/isoform-methyl-beta-values-summary.tsv.gz` 
- `results/isoform-methyl-beta-values-summary.jsonl.gz`

