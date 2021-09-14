FROM rocker/tidyverse:3.6.0
# create an R user 
ENV USER rstudio



ADD ./analysis/scripts/install_bioc.R install_bioc.R

#ADD ./data/histologies.tsv histologies.tsv
#ADD ./data/gene-counts-rsem-expected_count-collapsed.rds gene-counts-rsem-expected_count-collapsed.rds
#ADD ./data/gene-expression-rsem-tpm-collapsed.rds gene-expression-rsem-tpm-collapsed.rds
#ADD ./data/efo-mondo-map.tsv efo-mondo-map.tsv
#ADD ./data/uberon-map-gtex-subgroup.tsv uberon-map-gtex-subgroup.tsv
#ADD ./data/ensg-hugo-rmtl-mapping.tsv ensg-hugo-rmtl-mapping.tsv

ADD ./analysis/run-Generate_Hist_GTEx_indices_file.R run-Generate_Hist_GTEx_indices_file.R
ADD ./analysis/run-deseq-analysis.R run-deseq-analysis.R 
ADD Dockerfile Dockerfile


RUN chmod 755 ./install_bioc.R && ./install_bioc.R	DESeq2
#RUN chmod 755 run_deseq.sh


RUN R -e "install.packages('optparse', dependencies = TRUE)"
RUN R -e "install.packages('jsonlite', dependencies = TRUE)"
#RUN R -e "install.packages('ggplot2', dependencies = TRUE)"


#WORKDIR /
#RUN chmod +x run_deseq.sh
#RUN ./run_deseq.sh

