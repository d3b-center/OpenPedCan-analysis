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
ADD ./Analyses/run_deseq.sh run_deseq.sh
ADD Dockerfile Dockerfile


RUN chmod 755 ./install_bioc.R && ./install_bioc.R	DESeq2


RUN R -e "install.packages('optparse', dependencies = TRUE)"
#RUN R -e "install.packages('this.path', dependencies = TRUE)"

WORKDIR /Analyses
#RUN echo "$PWD"
RUN run_deseq.sh
