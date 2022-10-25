# OpenPedCan Methylation Analysis

## Purpose

Preprocess probe hybridization intensity values of selected methylated and unmethylated cytosine (CpG) loci into usable methylation measurements for the [Pediatric Open Targets, OPenPedCan-analysis](https://github.com/PediatricOpenTargets/OpenPedCan-analysis) raw DNA methylation array datasets. 

## Data description 

#### TARGET
The TARGET Illumina `Infinium HumanMethylation 450k BeadChip`  methylation arrays and sample metadata for the following pediatric cancers were downloaded from the [TARGET project website](https://ocg.cancer.gov/programs/target/target-methods):
 
- [Neuroblastoma (NBL)](https://target-data.nci.nih.gov/Public/NBL/methylation_array/)
- [Osteosarcoma (OS)](https://target-data.nci.nih.gov/Public/OS/methylation_array/)
- [Clear Cell Sarcoma of the Kidney (CCSK)](https://target-data.nci.nih.gov/Public/CCSK/methylation_array/)
- [Wilms Tumor (WT)](https://target-data.nci.nih.gov/Public/WT/methylation_array/)

###  Children's Brain Tumor Network (CBTN)
The [Children's Brain Tumor Network (CBTN)](https://cbtn.org/) `Infinium HumanMethylation EPIC (850k) BeadChip` methylation arrays and sample metadata for several Pediatric brain tumors.

## Analysis

- The TARGET Illumina methylation analysis results available on the [TARGET project website](https://ocg.cancer.gov/programs/target/target-methods) were preprocessed with different methylation software packages, including `minfi` (AML), `BeadStudio` (CCSK and WT), `methylumi` (NBL), and `Lumi+BMIQ` (OS). We have preprocessed all the TARGET and CBTN cancer types with Illumina arrays and using the updated version of [minfi Bioconductor package](https://academic.oup.com/bioinformatics/article/33/4/558/2666344). We utilized and `preprocessFunnorm` preprocessing method when an array dataset has control samples (i.e., normal and tumor samples) or multiple OpenPedcan cancer groups and `preprocessQuantile` when an array dataset has only tumor samples from a single OpenPedcan cancer group to estimate usable methylation measurements (Beta and M values) and copy number (cn-values) for OpenPedCan.



## General usage of scripts


#### `run-preprocess-illumina-arrays.sh`
This is a bash script wrapper for setting input file paths for the main analysis script, `01-preprocess-illumina-arrays.R` All file paths set in this script relative to the module directory. Therefore, this script should always run as if it were being called from the directory it lives in, the module directory (`OpenPedCan-analysis/analyses/methylation-preprocessing`).

```
bash run-preprocess-illumina-arrays.sh
```

#### `01-preprocess-illumina-arrays.R`
Preprocesses raw Illumina Infinium HumanMethylation BeadArrays (450K and 850k) intensities using `minfi Bioconductor package` into usable methylation measurements (Beta and M values) and copy number (cn-values) for OpenPedCan datasets. 
- `BiocManager::install("minfi")`

Addition data packages for `Ilumina Infinium HumanMethylation BeadArrays` that don't get installed automatically with `minfi`  and will need to be installed separately as folllows:
- `BiocManager::install("IlluminaHumanMethylation27kmanifest")`
- `BiocManager::install("IlluminaHumanMethylation450kmanifest")`
- `BiocManager::install("IlluminaHumanMethylationEPICmanifest")`
- `BiocManager::install("IlluminaHumanMethylation27kanno.ilmn12.hg19")`
- `BiocManager::install("IlluminaHumanMethylation450kanno.ilmn12.hg19")`
- `BiocManager::install("IlluminaHumanMethylationEPICanno.ilm10b4.hg19")`


In some `Ububtu OS` flavors, error occurs from the `preprocessCore library` is installed by `BiocManger` when `minfi` calls the normalization functions. The workaround is to [disable threading](https://support.bioconductor.org/p/122925/) as shown below. This is not an issue on Mac and Redhat OS. 
- `BiocManager::install("preprocessCore", configure.args="--disable-threading", force = TRUE)`

**Argument descriptions:**
```
Usage: 01-preprocess-illumina-arrays.R [options]


Options:
	--base_dir=CHARACTER
		The absolute path of the base directory containing sample 
              array IDAT files.

	--metadata_file=CHARACTER
		The metedata file associated with the sample array data
              files.

	--controls_present
		preprocesses the Illumina methylation array using the of
              the following minfi methods:
              - preprocessFunnorm: when array dataset contains either control
                                   samples (i.e., normal and tumor samples) or 
                                   multiple OpenPedcan cancer groups (TRUE)
              - preprocessQuantile: when an array dataset has only tumor samples 
                                    from a single OpenPedcan cancer group (FALSE)
              Default is TRUE (preprocessFunnorm)

	--snp_filter
		If TRUE, drops the probes that contain either a SNP at
              the CpG interrogation or at the single nucleotide extension.
              Default is TRUE

	-h, --help
		Show this help message and exit
```


#### `02-merge-methyl-matrices.R`
Merges methylation beta-values, m-values, and cp-values matrices for all pre-processed array datasets.

```
Rscript --vanilla 02-merge-methyl-matrices.R
```

## Input datasets

#### `Methylation arrays:`
Methylation array datasets are avaliable on the CHOP HPC `Isilon` sever (location: `/mnt/isilon/opentargets/wafulae/methylation-preprocessing/data/`). Please contact `Avin Farrel (@afarrel)` for access. 
- `data/NBL/*.idat` - Neuroblastoma (NBL) TARGET tumor sample arrays
- `data/OS/*.idat` - Osteosarcoma (OS) TARGET tumor sample arrays
- `data/CCSK/*.idat` - Clear Cell Sarcoma of the Kidney (CCSK) TARGET tumor sample arrays
- `data/WT/*.idat` - Wilms Tumor (WT) TARGET tumor sample arrays
- `data/AML/*.idat` - Acute Myeloid Leukemia (AML) TARGET tumor sample arrays
- `data/CBTN/*.idat` - Mutilple CBTN pediatric brian tumor sample arrays

## Results
Result files of methylation `beta-values`, `M-values` , `cn-values` are too large to upload to this repository and available on OpenPedCan data release s3 Bucket.
- `results/methyl-beta-values.rds`
- `results/methyl-m-values.rds`
- `results/methyl-cn-values.rds`


## High Performance Computing (HPC)

In addition to the base scripts, this module contains the necessary components
to perform the more resource intensive steps remotely using Docker, Common
Workflow Language (CWL), and CAVATICA.

### Docker

This module contains a Dockerfile. That Dockerfile is used for running pieces
of this module in a CWL environment. The image generated by the Dockerfile is
stored on DockerHub, and it is provided here for reference. If you wish to
build the Dockerfile yourself, use the following command substituting in your
desired `image_name` and `image_version`:
`docker build -t <image_name>:<image_version> .`

### Common Workflow Language (CWL)

In this module, there are two folders containing CWL files: `tools` and
`workflows`. The tools directory contains many files that contain the necessary
information to build the command lines for the various commands used to
preprocess the Illumina Methylation IDAT files. The `workflows` directory
contains CWL workflows. Workflows act as wrappers for the CWL tools. Workflows
define what the user is allowed to hand in to the workflow, what the user will
receive as an output, and how intermediate files and/or values are passed
between the tools.

### CAVATICA

To use the above tools or workflow(s), the user must upload them to CAVATICA.
To do that, the user must download scripts and publish an application.
Following command can be used to publish an application on CAVATICA:
`sbpack <sbg profile>  <user>/<projectname>/<workflowname> <path/to/workflow.cwl>`
Refer to this link for instructions on setting up [sbpack](https://docs.cavatica.org/docs/maintaining-and-versioning-cwl-on-external-tool-repositories).
