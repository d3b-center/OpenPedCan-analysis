set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
# copied from the run_in_ci.sh file at
# <https://github.com/AlexsLemonade/OpenPBTA-analysis/blob/master/scripts/>
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

mkdir -p results

## Match ensembl to gene_symbol using gtf file

Rscript --vanilla gene_ensembl_id_from_gtf.R --gtf_file input/gencode.v28.annotation.gtf.gz --output_file results/ensembl_gene_symbol_gtf_genode_v28.tsv
Rscript --vanilla gene_ensembl_id_from_gtf.R --gtf_file input/gencode.v38.annotation.gtf.gz --output_file results/ensembl_gene_symbol_gtf_genode_v38.tsv

## Merge gencode v28 and v38 results and input/open_ped_can_v7_ensg-hugo-rmtl-mapping.tsv

Rscript --vanilla merge_gencode_v28_v38_open_ped_can_v7_gene_ensg_symbol_mapping_files.R
# creates ensembl_gene_symbol_gtf_genode_v28_v38_merged.tsv

## Merge PMTL
Rscript -e "rmarkdown::render('add_pmtl_ens_hugo.Rmd')"

Rscript -e "rmarkdown::render('qc_ensg_hugo_pmtl_mapping.Rmd', clean = TRUE)"
