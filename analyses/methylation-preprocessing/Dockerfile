FROM rocker/tidyverse:4.2

RUN apt-get update \
    && apt-get -y --no-install-recommends install \
    libbz2-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

RUN ${R_HOME}/site-library/littler/examples/installBioc.r minfi IlluminaHumanMethylation27kmanifest IlluminaHumanMethylation450kmanifest IlluminaHumanMethylationEPICmanifest IlluminaHumanMethylation27kanno.ilmn12.hg19 IlluminaHumanMethylation450kanno.ilmn12.hg19 IlluminaHumanMethylationEPICanno.ilm10b4.hg19

RUN Rscript -e 'BiocManager::install("preprocessCore", configure.args="--disable-threading", force = TRUE)' 

RUN install2.r optparse

ADD Dockerfile .
