## To run, 
```
bash run-gene-mapping.sh
```

# Match ensembl to gene_symbol using gtf files and OpenPedCan v7 `ensg-hugo-rmtl-mapping.tsv`

`gene_match/gene_ensembl_id_from_gtf.R`: Read GTF file and formats `attributes` to extract gene symbol with gene ensembl ID.

GTF file sources:

- gencode v27 <http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_27>/gencode.v27.annotation.gtf.gz
- gencode v28 <http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_28>/gencode.v28.annotation.gtf.gz
- gencode v36 <http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_36>/gencode.v36.annotation.gtf.gz
- gencode v38 <http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_38>/gencode.v38.annotation.gtf.gz
- gencode v39 <http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_39>/gencode.v39.annotation.gtf.gz


`input/open_ped_can_v7_ensg-hugo-rmtl-mapping.tsv` source: <https://s3.amazonaws.com/kf-openaccess-us-east-1-prd-pbta/open-targets/v7/ensg-hugo-rmtl-mapping.tsv>

`gene_match/merge_gencode_v28_v38_open_ped_can_v7_gene_ensg_symbol_mapping_files.R`: Merges v26,v28, v36, v38, and v39 gencode versions and OpenPedCan v7 `ensg-hugo-rmtl-mapping.tsv`.

`gene_match/add_pmtl_ens_hugo.Rmd`: Merges PMTL v 1.1 with #`ensembl_gene_symbol_gtf_genode_v28_v38_open_ped_can_v7_merged.tsv`
`ensembl_gene_symbol_gtf_genode_all_open_ped_can_v7_merged.tsv`

## Package version

org.Hs.eg.db 3.7.0
GenomicFeatures 1.34.3
AnnotationDbi 1.44.0

## Note :
Since some of the scripts require high CPU processing capacity, this module must be run on EC2.
