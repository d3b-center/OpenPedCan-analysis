# Load libraries -------------------------------------------
library(optparse)
library(tidyverse)
library(signature.tools.lib) # contains the signal signatures

`%>%` <- dplyr::`%>%`

# Set up command line options -------------------------------
option_list <- list(
  make_option(c("--abbreviated"),
              type = "integer", # should be integer or plays poorly with CI shell script parameter
              default = FALSE,
              action =  "store_true",
              help = "Run an abbreviated analysis with fewer iterations for `sigfit`? This arg will be _ignored_ if --method is not `sigfit`.")
)


# Parse and check command line options ----------------------
opt <- parse_args(OptionParser(option_list = option_list))

# Full or abbreviated for MCMC?
if (opt$abbreviated == 1) {
  n_iter <- 10 # CI time-saver
} else {
  n_iter <- 3000 # Full analysis
}


# Set up directories, input/output files ----------------------------------

# Path to root of project:
proj_root_path <- file.path( rprojroot::find_root(rprojroot::has_dir(".git")) )
analysis_path <- file.path(proj_root_path, "analyses", "mutational-signatures")


# Path to input and output files:
maf_file <- file.path(proj_root_path, "data", "snv-consensus-plus-hotspots.maf.tsv.gz") # We consider _all_ WGS and WXS mutations here
meta_file      <- file.path(proj_root_path, "data", "histologies.tsv")
# Output files:
decon_fitted_file  <- file.path(analysis_path, "results", "fitted_exposures_signal-cns_deconstructSigs.rds")
results_df_file <- file.path("results", "deconstructSigs_cns_exposures_merged.tsv")


# Load CNS signatures 
refsig_cns_matrix <- t( getOrganSignatures("CNS", version = 1) )

# Perform extraction -------------------------------
# Read in the MAF file
maf <- data.table::fread(maf_file, data.table = FALSE)

# Read in histology file and filter for PBTA samples
meta <- readr::read_tsv(meta_file, guess_max = 10000) %>%
  filter(cohort == 'PBTA')

# Filter maf file to only include PBTA samples
maf <- maf %>%
  filter(Tumor_Sample_Barcode %in% meta$Kids_First_Biospecimen_ID)

# Prep mutations file for signature fitting 
sigs_input <- deconstructSigs::mut.to.sigs.input(
  mut.ref = maf,
  sample.id = "Tumor_Sample_Barcode",
  chr = "Chromosome",
  pos = "Start_Position",
  ref = "Reference_Allele",
  alt = "Allele",
  bsg = BSgenome.Hsapiens.UCSC.hg38::BSgenome.Hsapiens.UCSC.hg38
)

# Use deconstructSigs to determine exposures to known CNS and save -------------------------
tumor_sample_ids <- maf %>%
  dplyr::filter(Tumor_Sample_Barcode %in% rownames(sigs_input)) %>%
  dplyr::distinct(Tumor_Sample_Barcode) %>%
  dplyr::pull(Tumor_Sample_Barcode)


fit <- lapply(tumor_sample_ids, function(sample_id) {
  #print(sample_id)
  # Determine the signatures contributing to the sample
  deconstructSigs::whichSignatures(
    tumor.ref = sigs_input,
    signatures.ref = as.data.frame(refsig_cns_matrix), # MUST BE DF!
    sample.id = sample_id,
    contexts.needed = TRUE
  )
})
readr::write_rds(fit, decon_fitted_file, compress = "gz")


# The real signature names: https://signal.mutationalsignatures.com/explore/studyTissueType/1-6
signature_names_df <- tibble::tibble(
  signature = factor(
    c("11", "1", "N6", "8", "MMR2", "18", "19", "3", "Other"), 
    levels = c("1", "3", "8", "11", "18", "19", "N6", "MMR2", "Other")),
  cns_names   = c(paste0("CNS_",LETTERS[1:8], ' ', 
                         paste('(RefSig', c("11", "1", "N6", "8", "MMR2", "18", "19", "3")), ')'), "Other")
)


# Convert CNS signature weights into tibble
decon_weights <- lapply(fit, "[[", "weights")
exposures_wide <- do.call(dplyr::bind_rows, decon_weights) %>%
  add_column('Kids_First_Biospecimen_ID' = unlist(lapply(decon_weights, rownames)), .before = 1) %>%
  dplyr::select(-c(2:9)) %>%
  tibble::as_tibble() 
unknown_weights <- lapply(fit, "[[", "unknown")
unknown_weights_array <- do.call(rbind, unknown_weights)
exposures <- exposures_wide %>%
  # use "Other" for unknown
  dplyr::mutate(Other = unknown_weights_array[,1]) %>%
  # key is column name in signature_names_df
  tidyr::gather(-Kids_First_Biospecimen_ID, key = "cns_names", value = "exposure") 

# Merge results with cancer group data to be used in subsequent analyses
results_df <- exposures %>% 
  # Merge with metadata
  dplyr::inner_join(
    meta %>%
      dplyr::select(Kids_First_Biospecimen_ID, broad_histology, cancer_group, tumor_descriptor)
  ) %>%
  # Drop unknown cancer groups
  tidyr::drop_na(cancer_group)

# Merge with correct signal names (already factored and ordered)
results_df <- results_df %>%   
  dplyr::inner_join(signature_names_df)  %>%
  dplyr::select(-cns_names) # remove signature column 

# Write `results_df` to a file since it will be used by the `04` notebook.
readr::write_tsv(results_df, results_df_file)
