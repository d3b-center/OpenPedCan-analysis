FROM rocker/tidyverse:3.6.0
# create an R user 
ENV USER rstudio



ADD ./Scripts/install_bioc.R install_bioc.R

ADD ./Data/histologies.tsv histologies.tsv
ADD ./Data/gene-counts-rsem-expected_count-collapsed.rds gene-counts-rsem-expected_count-collapsed.rds
ADD ./Data/gene-expression-rsem-tpm-collapsed.rds gene-expression-rsem-tpm-collapsed.rds
ADD ./Data/efo-mondo-map.tsv efo-mondo-map.tsv
ADD ./Data/ensg-hugo-rmtl-mapping.tsv ensg-hugo-rmtl-mapping.tsv

ADD ./Analyses/deseq_analysis/run-DESeq-analysis.R run-DESeq-analysis.R 

ADD Dockerfile Dockerfile


RUN chmod 755 ./install_bioc.R && ./install_bioc.R \
    DESeq2


CMD Rscript --vanilla run-DESeq-analysis.R --hist_file histologies.tsv --counts_file gene-counts-rsem-expected_count-collapsed.rds --tpm_file gene-expression-rsem-tpm-collapsed.rds --efo_mondo_file efo-mondo-map.tsv --ensg_hugo_file ensg-hugo-rmtl-mapping.tsv
