FROM rocker/tidyverse:3.6.0
# create an R user 
ENV USER rstudio



ADD ./analysis/scripts/install_bioc.R install_bioc.R

ADD ./data/histologies.tsv histologies.tsv
ADD ./data/gene-counts-rsem-expected_count-collapsed.rds gene-counts-rsem-expected_count-collapsed.rds
ADD ./data/gene-expression-rsem-tpm-collapsed.rds gene-expression-rsem-tpm-collapsed.rds
ADD ./data/efo-mondo-map.tsv efo-mondo-map.tsv
ADD ./data/uberon-map-gtex-subgroup.tsv uberon-map-gtex-subgroup.tsv
ADD ./data/ensg-hugo-rmtl-mapping.tsv ensg-hugo-rmtl-mapping.tsv

ADD ./analysis/run-DESeq-Input-Subsetting.R run-DESeq-Input-Subsetting.R
ADD ./analysis/run-DESeq-analysis.R run-DESeq-analysis.R 
#ADD run_deseq.sh run_deseq.sh
ADD Dockerfile Dockerfile


RUN chmod 755 ./install_bioc.R && ./install_bioc.R	DESeq2
#RUN chmod 755 run_deseq.sh


#RUN R -e "install.packages('optparse', dependencies = TRUE)"
RUN R -e "install.packages('jsonlite', dependencies = TRUE)"
RUN R -e "install.packages('ggplot2', dependencies = TRUE)"


WORKDIR /
#RUN chmod +x run_deseq.sh
#RUN ./run_deseq.sh


CMD Rscript --vanilla run-DESeq-Input-Subsetting.R
#        --hist_file histologies.tsv \
#        --counts_file gene-counts-rsem-expected_count-collapsed.rds \
#        --tpm_file gene-expression-rsem-tpm-collapsed.rds  \
#        --efo_mondo_file data/efo-mondo-map.tsv \
#        --gtex_subgroup_uberon data/uberon-map-gtex-subgroup.tsv \
#        --ensg_hugo_file data/ensg-hugo-rmtl-mapping.tsv \
#        --outdir results
