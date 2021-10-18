# Author: Sangeeta Shukla

# Load required libraries
suppressPackageStartupMessages(library(optparse))


# read params
option_list <- list(
  make_option(c("-c", "--tsv_file"), type = "character",
              help = "TSV data file name"),
  make_option(c("-o", "--outdir"), type = "character",
              help = "Output directory name")
)

# parse the parameters
opt <- parse_args(OptionParser(option_list = option_list))


#args <- commandArgs(trailingOnly = TRUE)

#tsv_file <- args[1]

tsv_file <- opt$tsv_file
outdir <- opt$outdir

print(paste("File name:", tsv_file, sep=" "))


tsv_data <- read.delim(tsv_file, header = TRUE, sep="\t")

# Create file handle for rds similar to tsv
rds_file <- paste(tsv_file,".rds",sep="")

# Save an object to rds file with same name as tsv file
saveRDS(tsv_data, file = paste(outdir,"/",rds_file,sep=""))
