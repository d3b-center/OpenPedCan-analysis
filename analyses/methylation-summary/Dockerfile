FROM rocker/tidyverse:4.1.0
LABEL maintainer="Alex Sickler <sicklera@chop.edu>"
LABEL description="tidyverse image with libraries needed to run OpenPedCan methylation summary module"

ENV OPTPARSE_VERSION 1.7.3
ENV BIOC_VERSION 3.14

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /rocker-build/

COPY requirements.txt .

RUN apt-get -y update \
    && apt-get -y install --no-install-recommends python3-pip \
    && R -e "BiocManager::install(version = \"${BIOC_VERSION}\")" \
    && R -e "BiocManager::install('GenomicRanges', version = \"${BIOC_VERSION}\")" \
    && R -e "BiocManager::install('rtracklayer')" \
    && R -e "remotes::install_version('optparse', version = \"${OPTPARSE_VERSION}\", dependencies=TRUE, repos='http://cran.us.r-project.org')" \
    && pip3 install --no-cache-dir -r requirements.txt \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY Dockerfile .
