# use knitr to convert a list of Rmd files to Rscripts

library(knitr)
library(optparse)
library(stringr)

option_list <- list(
  make_option(
    opt_str = "--file",
    type = "character",
    help = "Text file with paths to notebooks to convert",
    metavar = "character"
  )
)

opts <- parse_args(OptionParser(option_list = option_list))
file <- file(opts$file, "r")

# loop through notebooks to convert
while (TRUE) {
  nb <- readLines(file, n = 1)
  if (length(nb) == 0) {
    break
  }
  # change Rmd to R
  out <- str_replace(nb, "Rmd", "R")
  # use knitr::purl() to convert; documentation = 2 retains text as comments
  knitr::purl(nb, out, documentation = 2)
}

close(file)
