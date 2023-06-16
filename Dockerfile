FROM rocker/tidyverse:4.2.3
MAINTAINER ccdl@alexslemonade.org
WORKDIR /rocker-build/

ARG github_pat=$GITHUB_PAT

ENV GITHUB_PAT=$github_pat

COPY scripts/install_bioc.r .

### Install apt-getable packages to start
#########################################

# Add curl, bzip2 and some dev libs
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    curl \
    bzip2 \
    zlib1g \
    libbz2-dev \
    liblzma-dev \
    libreadline-dev

# libgmp3-dev is needed for signature.tools.lib to install
RUN apt-get -y --no-install-recommends install \
    libgmp3-dev

# libmagick++-dev is needed for coloblindr to install
RUN apt-get -y --no-install-recommends install \
    libgdal-dev \
    libudunits2-dev \
    libmagick++-dev

# Required for installing pdftools, which is a dependency of gridGraphics
RUN apt-get -y --no-install-recommends install \
    libpoppler-cpp-dev
    
# Required for installing  MM2S, which is a dependency of igraph 
RUN apt-get -y --no-install-recommends install \
    libglpk-dev

# Required dependency for running GISTIC
RUN apt-get -y --no-install-recommends install \
    libncurses5

# Install pip3 and low-level python installation reqs
RUN apt-get -y --no-install-recommends install \
    python3-pip  python3-dev
RUN ln -s /usr/bin/python3 /usr/bin/python    
RUN pip3 install \
    "Cython==0.29.15" \
    "setuptools==46.3.0" \
    "six==1.14.0" \
    "wheel==0.34.2" 

# Install java
RUN apt-get -y --no-install-recommends install \
    default-jdk


# Required for running matplotlib in Python in an interactive session
RUN apt-get -y --no-install-recommends install \
    python3-tk

# Standalone tools and libraries
################################

# Required for mapping segments to genes
# Add bedtools
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.28.0/bedtools-2.28.0.tar.gz && \
    tar -zxvf bedtools-2.28.0.tar.gz && rm -f bedtools-2.28.0.tar.gz && \
    cd bedtools2 && \
    make && \
    mv bin/* /usr/local/bin && \
    cd .. && rm -rf bedtools2

# Add bedops per the BEDOPS documentation
RUN wget https://github.com/bedops/bedops/releases/download/v2.4.37/bedops_linux_x86_64-v2.4.37.tar.bz2 && \
    tar -jxvf bedops_linux_x86_64-v2.4.37.tar.bz2 && \
    rm -f bedops_linux_x86_64-v2.4.37.tar.bz2 && \
    mv bin/* /usr/local/bin

# HTSlib
RUN wget https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 && \
    tar -jxvf htslib-1.9.tar.bz2 && rm -f htslib-1.9.tar.bz2 && \
    cd htslib-1.9 && \
    ./configure && \
    make && \
    make install && \
    cd .. && rm -rf htslib-1.9


#### R packages
###############

# Commonly used R packages
RUN ./install_bioc.r \
    class \
    cluster \
    data.table \
    DT \
    flextable \
    foreign \
    GGally \
    lattice \
    MASS \
    Matrix \
    mgcv \
    nlme \
    nnet \
    optparse \
    R.utils \
    RColorBrewer \
    rpart \
    rprojroot \
    survival \
    viridis \
    vroom \
    openxlsx \
    ids
    


# Required for interactive sample distribution plots
# map view is needed to create HTML outputs of the interactive plots
RUN ./install_bioc.r \
    #gdalUtils \
    leafem \
    leafpop \
    lwgeom \
    mapview \
    plainview \
    sf \
    stars

# Installs packages needed for plottings
# treemap, interactive plots, and hex plots
# Rtsne and umap are required for dimension reduction analyses
RUN ./install_bioc.r \
    corrplot \
    d3r \
    ggfortify \
    ggpubr \
    ggrepel \
    ggsci \
    ggsignif \
    gridGraphics \
    hexbin \
    pheatmap \
    Rtsne \
    spatial \
    treemap \
    umap  \
    UpSetR \
    VennDiagram 

# Install rjava
RUN ./install_bioc.r \
    rJava 

# Need for survminer for doing survival analysis
RUN ./install_bioc.r \
    cmprsk \
    survMisc \
    survminer

# maftools for proof of concept in create-subset-files
RUN ./install_bioc.r \
    maftools

# ComplexHeatmap
RUN ./install_bioc.r \
    ComplexHeatmap

# This is needed for the CNV frequency and proportion aberration plots
RUN ./install_bioc.r \
    GenVisR

# These packages are for the genomic region analysis for snv-callers
RUN ./install_bioc.r \
    annotatr \
    TxDb.Hsapiens.UCSC.hg38.knownGene \
    org.Hs.eg.db \
    BSgenome.Hsapiens.UCSC.hg19 \
    BSgenome.Hsapiens.UCSC.hg38

# Packages for expression normalization and batch correction
RUN ./install_bioc.r \
    preprocessCore \
    sva


## This is deprecated
#  # These packages are for single-sample GSEA analysis
#  RUN ./install_bioc.r 'GSEABase', 'GSVA'

# Required for sex prediction from RNA-seq data
RUN ./install_bioc.r \
    glmnet \
    glmnetUtils \
    caret \
    e1071 


# bedr package & check to make sure binaries are available by loading
RUN ./install_bioc.r \
    bedr \
    && Rscript -e "library(bedr)"

# qdapRegex is for the fusion analysis
RUN ./install_bioc.r \
    qdapRegex 

# packages required for collapsing RNA-seq data by removing duplicated gene symbols
RUN ./install_bioc.r \
    rtracklayer

# TCGAbiolinks for TMB compare analysis
RUN R -e "remotes::install_github('RDocTaskForce/parsetools', ref = '1e682a9f4c5c7192d22e8985ce7723c09e98d62b', dependencies = TRUE)" \
    && R -e "remotes::install_github('RDocTaskForce/testextra', ref = '4e5dfac8853c08d5c2a8790a0a1f8165f293b4be', dependencies = TRUE)" \
    && R -e "remotes::install_github('halpo/purrrogress', ref = '54f2130477f161896e7b271ed3ea828c7e4ccb1c', dependencies = TRUE)" \
    && ./install_bioc.r TCGAbiolinks

# Install for mutation signature analysis
RUN ./install_bioc.r \
    ggbio

# CRAN package msigdbr and GSVA for gene-set-enrichment-analysis
RUN ./install_bioc.r \
    msigdbr \
    GSVA


# package required for immune deconvolution
RUN R -e "remotes::install_github('omnideconv/immunedeconv', ref = 'a2bdf31d39111e46c7cefc03ebdbb28457a0d08c', dependencies = TRUE)"

# package to read yaml file
RUN ./install_bioc.r \
    rlist

RUN R -e "remotes::install_github('const-ae/ggupset', ref = '7a33263cc5fafdd72a5bfcbebe5185fafe050c73', dependencies = TRUE)"

# This is needed to create the interactive pie chart
RUN R -e "remotes::install_github('timelyportfolio/sunburstR', ref = 'd40d7ed71ee87ca4fbb9cb8b7cf1e198a23605a9', dependencies = TRUE)"

# This is needed to create the interactive treemap
RUN R -e "remotes::install_github('timelyportfolio/d3treeR', ref = '0eaba7f1c6438e977f8a5c082f1474408ac1fd80', dependencies = TRUE)"

# Need this package to make plots colorblind friendly
RUN R -e "remotes::install_github('clauswilke/colorblindr', ref = '1ac3d4d62dad047b68bb66c06cee927a4517d678', dependencies = TRUE)"

# remote package EXTEND needed for telomerase-activity-prediciton analysis
RUN R -e "remotes::install_github('NNoureen/EXTEND', ref = '467c2724e1324ef05ad9260c3079e5b0b0366420', dependencies = TRUE)"

# package required for shatterseek
RUN R -e "withr::with_envvar(c(R_REMOTES_NO_ERRORS_FROM_WARNINGS='true'), remotes::install_github('parklab/ShatterSeek', ref = '83ab3effaf9589cc391ecc2ac45a6eaf578b5046', dependencies = TRUE))"

# Packages required for rna-seq-composition
RUN ./install_bioc.r \
    EnvStats \
    janitor 

# Patchwork for plot compositions
RUN R -e "remotes::install_github('thomasp85/patchwork', ref = 'c67c6603ba59dd46899f17197f9858bc5672e9f4')"

# This is required for creating a treemap of the broad histology and integrated diagnoses
RUN R -e "remotes::install_github('wilkox/treemapify', ref = 'e70adf727f4d13223de8146458db9bef97f872cb', dependencies = TRUE)"

# Need this specific version of circlize so it has hg38
RUN R -e "remotes::install_github('jokergoo/circlize', ref = 'b7d86409d7f893e881980b705ba1dbc758df847d', dependencies = TRUE)"

# signature.tools.lib needed for mutational-signatures 
RUN R -e "remotes::install_github('Nik-Zainal-Group/signature.tools.lib', ref = 'a54e5d904d091b90ad3b0f9663133e178c36b9aa', dependencies = TRUE)"

# Install python packages
##########################

# Install python3 tools and ALL dependencies
RUN pip3 install \
    "appdirs==1.4.4" \
    "attrs==23.1.0" \
    "backcall==0.2.0" \
    "bleach==6.0.0" \
    "bx-python==0.9.0" \
    "certifi==2023.5.7" \
    "chardet==5.1.0" \
    "ConfigArgParse==1.5.3" \
    "CrossMap==0.6.5" \
    "cycler==0.11.0" \
    "datrie==0.8.2" \
    "decorator==5.1.1" \
    "defusedxml==0.7.1" \
    "docutils==0.20" \
    "entrypoints==0.4" \
    "gitdb==4.0.10" \
    "GitPython==3.1.31" \
    "idna==3.4" \
    "importlib-metadata==6.6.0" \
    "ipykernel==6.23.0" \
    "ipython==8.13.2" \
    "ipython-genutils==0.2.0" \
    "jedi==0.18.2" \
    "Jinja2==3.1.2" \
    "jsonschema==4.17.3" \
    "jupyter-client==8.2.0" \
    "jupyter-core==5.3.0" \
    "kiwisolver==1.4.4" \
    "MarkupSafe==2.1.2" \
    "matplotlib==3.7.1" \
    "mistune==2.0.5" \
    "mizani==0.9.0" \
    "nbconvert==7.4.0" \
    "nbformat==5.8.0" \
    "notebook==6.5.4" \
    "numpy==1.24.3" \
    "packaging==23.1" \
    "palettable==3.3.3" \
    "pandas==2.0.1" \
    "pandocfilters==1.5.0" \
    "parso==0.8.3" \
    "patsy==0.5.3" \
    "pexpect==4.8.0" \
    "pickleshare==0.7.5" \
    "plotnine==0.12.1" \
    "prometheus-client==0.16.0" \
    "prompt-toolkit==3.0.38" \
    "psutil==5.9.5" \
    "ptyprocess==0.7.0" \
    "pyarrow==12.0.0" \
    "pybedtools==0.9.0" \
    "pyBigWig==0.3.22" \
    "Pygments==2.15.1" \
    "pyparsing==3.0.9" \
    "pyreadr==0.4.7" \
    "pyrsistent==0.19.3" \
    "pysam==0.21.0" \
    "python-dateutil==2.8.2" \
    "pytz==2023.3" \
    "PyYAML==6.0" \
    "pyzmq==25.0.2" \
    "ratelimiter==1.2.0.post0" \
    "requests==2.30.0" \
    "rpy2==3.5.0" \
    "scikit-learn==1.2.2" \
    "scipy==1.10.1" \
    "seaborn==0.12.2" \
    "Send2Trash==1.8.2" \
    "six==1.16.0" \
    "smmap==5.0.0" \
    "snakemake==7.25.3" \
    "statsmodels==0.14.0" \
    "terminado==0.17.1" \
    "testpath==0.6.0" \
    "tornado==6.3.1" \
    "traitlets==5.9.0" \
    "tzlocal==4.3" \
    "urllib3==2.0.2" \
    "utils==1.0.1" \
    "wcwidth==0.2.6" \
    "webencodings==0.5.1" \
    "widgetsnbextension==4.0.7" \
    "wrapt==1.15.0" \
    "zipp==3.15.0" \
    "openpyxl==3.1.2" \
    && rm -rf /root/.cache/pip/wheels


# MATLAB Compiler Runtime is required for GISTIC, MutSigCV
# Install steps are adapted from usuresearch/matlab-runtime
# https://hub.docker.com/r/usuresearch/matlab-runtime/dockerfile

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -q update && \
    apt-get install -q -y --no-install-recommends \
    xorg

# This is the version of MCR required to run the precompiled version of GISTIC
RUN mkdir /mcr-install-v83 && \
    mkdir /opt/mcr && \
    cd /mcr-install-v83 && \
    wget https://www.mathworks.com/supportfiles/downloads/R2014a/deployment_files/R2014a/installers/glnxa64/MCR_R2014a_glnxa64_installer.zip && \
    unzip -q MCR_R2014a_glnxa64_installer.zip && \
    rm -f MCR_R2014a_glnxa64_installer.zip && \
    ./install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    cd / && \
    rm -rf mcr-install-v83

WORKDIR /home/rstudio/
# GISTIC installation
RUN mkdir -p gistic_install && \
    cd gistic_install && \
    wget -q ftp://ftp.broadinstitute.org/pub/GISTIC2.0/GISTIC_2_0_23.tar.gz && \
    tar zxf GISTIC_2_0_23.tar.gz && \
    rm -f GISTIC_2_0_23.tar.gz && \
    rm -rf MCR_Installer && \
    chown -R rstudio:rstudio /home/rstudio/gistic_install && \
    chmod 755 /home/rstudio/gistic_install
WORKDIR /rocker-build/

# Install multipanelfigure, required for transcriptomic overview figure
# gplots for gistic comparison
RUN ./install_bioc.r \
    multipanelfigure \
    gplots

# Molecular subtyping MB
RUN R -e "remotes::install_github('d3b-center/medullo-classifier-package', ref = 'e3d12f64e2e4e00f5ea884f3353eb8c4b612abe8', dependencies = TRUE, upgrade = FALSE)" \
    && ./install_bioc.r MM2S
# More recent version of sva required for molecular subtyping MB
RUN R -e "remotes::install_github('jtleek/sva-devel@123be9b2b9fd7c7cd495fab7d7d901767964ce9e', dependencies = FALSE, upgrade = FALSE)"

# Packages required for de novo mutational signatures
RUN install2.r --error --deps TRUE \
    lsa
    
# Package for kinase domain retention for fusions
RUN ./install_bioc.r \
    EnsDb.Hsapiens.v86 \
    ensembldb

RUN R -e "remotes::install_github('d3b-center/annoFuseData',ref = '321bc4f6db6e9a21358f0d09297142f6029ac7aa', dependencies = TRUE)"

RUN R -e "remotes::install_github('d3b-center/annoFuse',ref = '55b4b862429fe886790d087b2f1c654689c691c4', dependencies = TRUE)"

# Latest deconstructSigs release for mut sigs analyses
RUN R -e "remotes::install_github('raerose01/deconstructSigs', ref = '41a705c5d80848121347d448cf9e2c58ff6b81ac', dependencies = TRUE)"

# Package for RNA-seq differential gene expression analysis
RUN ./install_bioc.r \
    DESeq2

# Package for removing unwanted variation from RNA-Seq data
RUN ./install_bioc.r \
    RUVSeq \
    EDASeq \
    edgeR \
    uwot \
    irlba

# Packages for RNA-seq expression boxplots (tumor-gtex-plots)
RUN ./install_bioc.r \
    tidyr \
    dplyr \
    ggplot2

# Package for querying gene IDs and symbols
RUN ./install_bioc.r \
    mygene

# Packages for focal-CN-file-prep module
RUN ./install_bioc.r \
    GenomicRanges

RUN R -e 'BiocManager::install(c("AnnotationDbi", "org.Hs.eg.db"))'

# Even though apt-get section at top, add installation here to avoid re-RUN
# previous steps in docker build.
# There are other out-of-order cases.
# We can reorganize this Dockerfile when CI is available, so it is easier to
# test for reproducibility.
# Install json processor jq
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    jq

WORKDIR /home/rstudio/
# AWS CLI installation
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    rm -rf aws*

# Install Desal latest release (v2.1.1)- converter for JSON, TOML, YAML, XML and CSV data formats
RUN sudo wget -qO /usr/local/bin/dasel "https://github.com/TomWright/dasel/releases/download/v2.1.1/dasel_linux_amd64" && \
    sudo chmod a+x /usr/local/bin/dasel

#### Please install your dependencies immediately above this comment.
#### Add a comment to indicate what analysis it is required for


WORKDIR /rocker-build/
