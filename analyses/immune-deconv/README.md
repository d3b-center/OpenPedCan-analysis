## Immune Deconvolution

**Module authors:** Komal S. Rathi ([@komalsrathi](https://github.com/komalsrathi)), updated Kelsey Keith ([@kelseykeith](https://github.com/kelseykeith))

### Description

The goal of this analysis is to use the R package `immunedeconv` to quantify and compare various immune cell types in the tumor microenvironment (TME) across various cancer and GTEx groups. 
The package `immunedeconv`, provides the following deconvolution methods: `xCell` (n = 64; immune and non-immune cell types), `CIBERSORT` (relative mode; n = 22 immune cell types); `CIBERSORT (abs.)` (absolute mode; n = 22 immune cell types), `TIMER` (n = 6), `EPIC` (n = 6), `quanTIseq` (n = 10) and `MCP-Counter` (n = 8). 

Both `CIBERSORT` and `CIBERSORT (abs.)` require two files i.e. `LM22.txt` and `CIBERSORT.R`, that are available upon request from https://cibersort.stanford.edu/. Please refer to https://icbi-lab.github.io/immunedeconv/articles/immunedeconv.html#special-case-cibersort for more details. We recommend using `xCell` instead when these files are not available to the user. 

### Method selection


We use two methods: xCell and quanTIseq. 


We chose xCell because it: 
1) is the most comprehensive deconvolution method and is able to deconvolute the maximum number of immune and non-immune cell types 
2) is highly robust against background predictions and 
3) can reliably identify the presence of immune cells at low abundances (0-1% infiltration depending on the immune cell type).

xCell outputs immune scores as arbitrary scores that represent cell type abundance. 
Importantly, these scores may be compared between samples (inter-sample comparisons), but _may not_ be compared across cell types or cancer types, as described in the [`immunedeconv` documentation](https://omnideconv.org/immunedeconv/articles/immunedeconv.html#interpretation-of-scores). This is in part because xCell is actually a signature-based method and not a deconvolution method, as is described in the [xCell Publication](https://doi.org/10.1186/s13059-017-1349-1):
> Unlike signature-based methods, which output independent enrichment scores per cell type, the output from deconvolution-based methods is the inferred proportions of the cell types in the mixture.

Therefore, we also use `quanTIseq` as a complementary method. Although `quanTIseq` looks at fewer cell types, the scores can be interpreted as absolute fractions, thereby allowing comparison _both_ across samples and cell types, [as described](https://omnideconv.org/immunedeconv/articles/immunedeconv.html#interpretation-of-scores).

### Analysis scripts

#### 01-immune-deconv.R

1. Inputs from data download

```
gene-expression-rsem-tpm-collapsed.rds
data/histologies.tsv
```

2. Function

This script deconvolutes immune cell types using the method of choice, either `xCell` or `quanTIseq`. Since `xCell` uses the variability among the samples for a linear transformation of the output score, we split the expression matrix into individual `cohorts + cancer_group` or `cohort + gtex_group` and deconvolute them separately. Once processed, all data is combined into a single rds file which can be used to do comparisons across various groups.

3. Output: 

```
results/{deconv_method}_output.rds
```

For `xCell`, the results in the rds file are predicted immune scores per cell type per input sample. These scores are not actual cell fractions but arbitrary scores representing enrichment of the cell types which can be compared across various cancer/gtex groups. The `quanTIseq` results, in contrast, provide an absolute score that can be interpreted as a cell fraction and the results in the rds file are the absolute scores per cell type per input sample. Depending on the user requirements, the output can also be used to create various visualizations. 

#### 02-summary-plots.R 

1. Input

```
results/{deconv_method}_output.rds
```

2. Function:

This script creates heatmaps from predicted immune scores.

3. Output

* `plots/{deconv_method}_heatmap_by_group.pdf`: heatmap of average immune scores per cell type per cancer group or GTEx group.

### Running the analysis

The following script will run the full analysis using either of the two methods of choice: `xCell` or `quanTIseq`. `xCell` is run by default, so to select `quanTIseq`, see code option in chunk below.

```
bash run-immune-deconv.sh
```
