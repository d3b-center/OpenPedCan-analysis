# Compare RNA-Seq workflows

**Contents**

- [Purpose](#purpose)
- [Usage](#usage)
  - [Correlation Coefficient](#correlation-coefficient)
  - [Software dependencies](#software-dependencies)

## Purpose
The pipeline-comparison module performs a comparative analysis of varying RNA-Seq workflows, offering insight into the correlation coefficient across workflows for counts at gene-level. Currently, the comparison is performed on the PPTC, KidsFirst, and JAX workflows.
Varieties of comparison include (a) comparison of the full gene set, at gene level (b) partial gene set, only homologous to mouse genome (c) comparison of the full gene set, at gene level with threshold on the TPM value (d) partial gene set, only homologous to mouse genome with thresold on the TPM value

## Usage
The input files must be two RNA-Seq TPM gene expression tables in tab separated formats (.tsv) 
Other input must also include the names of the workflows to compare and a file containing a list of genes homologous to mouse


### Correlation Coefficient
Generates the correlation matrix along with standard and probably error of the correlation coefficient
The probable error can be used to interpret if the correlation coefficient is significant for using the data for any downstream analysis.


### Standard error of Correlation Coefficient
The standard error of correlation coeffiecient is defined by below formula
```
s_err = 1 - (r^2))/sqrt(n)
where r=correlation coeffiecient, n=number of samples
```

### Probable error of Correlation Coefficient
The standard error of correlation coeffiecient is defined by below formula
```
p_err = 0.6745*((1 - (r^2))/sqrt(n))
where r=correlation coeffiecient, n=number of samples
```

### Interpretation
Probable error determines the limits for correlation coefficient for the population as [r-p_err, r+p_err]

Additionally, if r > 6p_err, it can be concluded that there is a definitely significant correlation between the two samples.

```

Required flags:
 - `—wf1_name` :name/abbreviation of one of the two workflows to be compared
 - `—wf2_name` :name/abbreviation of the other workflow to be compared
 - `—wf1_file` :gene expression TSV data file from workflow 1
 - `—wf2_file` :gene expression TSV data file from workflow 2
  - `—input_homologs` list of mouse genes homologous to human genes found in above workflows gene set
  - `—output_filename` name of the output file. This is optional. The script will otherwise use the names of the workflows from previous flags to create a unique output file name.
```

Input files:
```
input/PPTC-KF-gene-expression-rsem-tpm-collapsed-matrix.tsv
input/PPTC-JAX-gene-expression-rsem-tpm-collapsed-matrix.tsv
input/Gene_ID_Matches.tsv
```

Output files:
```
results/results_KF_JAX_comparison.tsv
```

### Thresholds
Additional comparison is performed setting a threshold on the TPM value used to calculate correlation coefficient. `02-..` script will be added once the data files are finalized




### Software dependencies
The analysis uses R 4.0.4 and requires the following libraries. Version numbers
are those currently in use and earlier or later versions may also be acceptable but have not been tested.
```
attached base packages:
stats     
graphics
grDevices
utils
datasets
methods
base     

other attached packages:
dplyr_1.0.9
tidyr_1.2.0
readr_2.1.2
rstudioapi_0.13
magrittr_2.0.3
hms_1.1.1
bit_4.0.4
tidyselect_1.1.2
R6_2.5.1
rlang_1.0.2      
fansi_1.0.3
tools_4.0.4
parallel_4.0.4
data.table_1.14.2
vroom_1.5.7
utf8_1.2.2
cli_3.3.0        
DBI_1.1.2
withr_2.5.0
ellipsis_0.3.2
bit64_4.0.5
assertthat_0.2.1
tibble_3.1.6
lifecycle_1.0.1  
crayon_1.5.1
purrr_0.3.4
tzdb_0.3.0
vctrs_0.4.1
glue_1.6.2
compiler_4.0.4
pillar_1.7.0     
generics_0.1.2
pkgconfig_2.0.3  
```
In addition, a `utils` module is included for certain shared functions.
