# Author: Sangeeta Shukla

# Load required libraries
suppressPackageStartupMessages(library(optparse))


# read params
option_list <- list(
  make_option(c("-c", "--tsv_file"), type = "character",
              help = "TSV data file name"),
  make_option(c("-o", "--outdir"), type = "character",
              help = "Output directory name", default = "."),
  make_option(c("-b", "--basename"), type = "character",
              help = "Output file basename")
)

# parse the parameters
opt <- parse_args(OptionParser(option_list = option_list))


#args <- commandArgs(trailingOnly = TRUE)

#tsv_file <- args[1]

tsv_file <- opt$tsv_file
outdir <- opt$outdir
outbase <- opt$basename

print(paste("File name:", tsv_file, sep=" "))


tsv_data <- read.delim(file=tsv_file, header = TRUE, sep="\t")

# Create file handle for rds similar to tsv
rds_file <- paste0(outdir, "/", outbase, ".rds")

# Save an object to rds file with same name as tsv file
saveRDS(tsv_data, file = rds_file)
