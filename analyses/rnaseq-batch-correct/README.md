## Batch Correction of RNA-seq expression matrices

**Module authors:** Komal Rathi ([@komalsrathi](https://github.com/komalsrathi)), Adam Kraya (@aadamk), Yuanchao Zhang (@logstar, initial piloting)

### Description

This module uses HRT Gene Atlas housekeeping genes to correct for batch effects for tumor-only and tumor-normal comparisons.
Batch correction is performed as follows:
1. Input genes from the HRT Atlas v1.0 (PMID: 32663312; `input/hk_genes_normals.rds`) are assumed to be non-differentially expressed between tumor subtypes and across tumor vs normal.
Differences in housekeeping genes are assumed to be the result of technical rather than true biological variation.  
(e.g. tumors are not expected to use housekeeping genes for a growth or proliferative advantage).
2. DESeq2 analysis is run without batch correction as a baseline.
3. [RUVg](https://bioconductor.org/packages/devel/bioc/vignettes/RUVSeq/inst/doc/RUVSeq.pdf), which uses negative control genes for correcting batch effects, is run using multiple possible factors (`k`)
4. Diagnostic plots showing p-value distributions and clustering before and after batch correction are generated.
5. The module then selects the `k` with the maximum sensitivity/specificity balance by considering changes in p-values
in positive and negative control gene sets. Three use cases are evaluated:
a. Neuroblastoma MYCN-amplified versus MYCN-N non amplified tumors with a positive control gene set corresponding to MSigDb gene sets
`KIM_MYCN_AMPLIFICATION_TARGETS_DN` (M2919) and `KIM_MYCN_AMPLIFICATION_TARGETS_UP` (M5329)
b. High Grade Glioma and Diffuse Midline Glioma `molecular_subtype` comparisons with a positive control gene set corresponding to
Additional file 4: Table S2 under `K27M vs WT day5`, where adj p < 0.05 (PMID: 35637482).
c. Tumor-normal comparison of HGG/DMG versus GTEx using a positive control gene set corresponding to cell cycle regulatory pathways with the following
```
msig.gs <- msigdbr::msigdbr(species = "Homo sapiens", category = 'C2')
msig.gs <- msig.gs %>%
  dplyr::filter(gs_name %in% grep('Cell_Cycle|Mitosis', gs_name, value = TRUE, ignore.case = T)) %>%
  dplyr::filter(gs_subcat %in% (grep('REACTOME', gs_subcat, value = T, ignore.case = T)))
  ```
6. DESeq2 results of the optimal method from 5 are provided and normalized counts are generated
as standard output for use in downstream visualizations.

### Analysis scripts

#### Run tumor-only RUVg analysis

The script below runs a tumor-only analysis for a specific cancer_group, using molecular subtype
as the default design variable. The script evaluates DESeq2-RUVg results by pulling in all analysis results across all k's,
evaluating changes in p-value for negative control genes (HRT Atlas genes) and positive control genes
that are analysis-specific. The script looks for k's that maximize sensitivity and specificity by
selecting the k that resulted in the most p-values increasing for negative control genes and decreasing
for positive control genes when correcting for batch effects.


Example run:

```sh
Rscript code/01-ruvseq-deseq.R \
--dataset 'target_nbl' \
--cohort_values 'TARGET' \
--cancer_group_values 'Neuroblastoma' \
--pos_c 'MYCN_targets_M2919_M18532.rds' \
--neg_c 'hk_genes_normals.rds' \
--k_value 5
```

Output files containing normalized counts, RUVg objects, and dge results are in the `output/[dataset]/deseq2-analysis/` folder

```sh
output/[dataset]/deseq2-analysis
└── *dge.tsv # DESeq2 DGE results
└── *pvalues.tsv # p-value results
└── *output.rds # normalized counts at all k's
```

#### Initial QC plots using PCA and UMAP

Here the goal is to create QC clustering plots using PCA and UMAP with the most variable genes (> 90% quantile) as well as housekeeping genes.

p-value histograms, PCA, and UMAP plots (.pdf):

```sh
# PCA, UMAP
plots/[dataset]/
├── *histogram.pdf # p-value histogram at all k's and for optimal k
├── *clustering.pdf # PCA and UMAP clustering results for all k and for optimal k
├── *controls.pdf # p-value histogram of negative control genes
└── *transcriptome.pdf # p-value histogram of full transcriptome
```
#### Run tumor-normal RUVg analysis

The script below runs a tumor-normal analysis for cancer groups (comma-separated) versus gtex subgroups (comma-separated)
creating a tumor-normal comparison in the design. A key parameter is `drop`, which is a user-specifiable
parameter which drops the initial n factors of variation to guard against removing true biological variation
across tumor and normal. The script evaluates DESeq2-RUVg results by pulling in all analysis results across all k's,
evaluating changes in p-value for negative control genes (HRT Atlas genes) and positive control genes
(Reactome Cell Cycle). The script looks for k's that maximize sensitivity and specificity by
selecting the k that resulted in the most p-values increasing for negative control genes and decreasing
for positive control genes when correcting for batch effect


Example run:

```sh
Rscript code/02-ruvseq-deseq-tn.R \
--dataset 'HGG-DMG_TN' \
--cohort_values 'PBTA,GTEx' \
--cancer_group_values 'Diffuse midline glioma,High-grade glioma/astrocytoma' \
--gtex_subgroups 'Brain - Cortex,Brain - Cerebellum' \
--k_value 5 \
--drop 2 \
--pos_c 'reactome_cell_cycle_msigdb_v7.5.1.rds' \
--neg_c 'hk_genes_normals.rds'
```

Output files containing normalized counts, RUVg objects, and dge results are in the `output/[dataset]/deseq2-analysis/` folder

```sh
output/[dataset]/deseq2-analysis
└── *dge.tsv # DESeq2 DGE results
└── *pvalues.tsv # p-value results
└── *output.rds # normalized counts
```

#### Initial QC plots using PCA and UMAP

Here the goal is to create QC clustering plots using PCA and UMAP with the most variable genes (> 90% quantile) as well as housekeeping genes.

p-value histograms, PCA, and UMAP plots (.pdf):

```sh
# PCA, UMAP
plots/[dataset]/
├── *histogram.pdf # p-value histogram at all k's and for optimal k
├── *clustering.pdf # PCA and UMAP clustering results for all k and for optimal k
├── *controls.pdf # p-value histogram of negative control genes
└── *transcriptome.pdf # p-value histogram of full transcriptome
```
