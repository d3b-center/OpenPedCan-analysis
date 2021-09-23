# Step 0: Invoke libraries
library(dplyr)

# Step 1: Read files
ensg <- read.delim("../../data/ensg-hugo-rmtl-mapping.tsv")
pmtl <- read.delim("input/PMTL_v1.1.tsv")


# Split original into NA and non-NA groups

ensg_no_na <- ensg %>%
  filter(!is.na(rmtl) | !is.na(version))

ensg_na <- ensg %>%
  filter(is.na(rmtl) | is.na(version))


#length(ensg_no_na$ensg_id) #442
#length(ensg_na$ensg_id) #94399
# Total 94841, split verified

# Search for duplicates in no_NA, just to be sure
uniq_ensg_no_na <- ensg_no_na[!duplicated(ensg_no_na[1:length(colnames(ensg_no_na))]),]
#length(uniq_ensg_no_na$ensg_id) #442
#length(unique(uniq_ensg_no_na$ensg_id)) #431, this means there is repetiotion over ID while gene_symbol is unique


# Search for duplicates in NA, should not be there
uniq_ensg_na <- ensg_na[!duplicated(ensg_na[1:length(colnames(ensg_na))]),]
#length(uniq_ensg_na$ensg_id) #94399, verified

# Search again, but only for ensg_id and gene_symbol
#uniq_ensg_na_2 <- ensg_na[!duplicated(ensg_na[1:2]),]
#length(uniq_ensg_na_2$ensg_id) #94399, verified


#Review pmtl before next steps
uniq_pmtl <- pmtl %>% 
  select(Ensembl_ID, Approved_Symbol)

#length(unique(uniq_pmtl$Ensembl_ID)) #470
#length(unique(uniq_pmtl$Approved_Symbol)) #471, that means there are repetions over ID while gene_symbol is unique

#length(uniq_pmtl$Ensembl_ID) #512, possibly because the additional columns in the file had unique values

#Remove duplicates for downstream use of the array
uniq_pmtl <- uniq_pmtl[!duplicated(uniq_pmtl[1:length(colnames(uniq_pmtl))]),]

# Found two "Symbol_Not_Found"
#pmtl_n_occur <- data.frame(table(uniq_pmtl$Ensembl_ID))
#uniq_pmtl[uniq_pmtl$Ensembl_ID %in% pmtl_n_occur$Var1[pmtl_n_occur$Freq > 1],]

# Re-verification
#length(unique(uniq_pmtl$Ensembl_ID)) #470
#length(unique(uniq_pmtl$Approved_Symbol)) #471, verified


# Map new pmtl to uniq_ensg_no_na

mapped_pmtl_no_na <- uniq_pmtl%>%
  filter(uniq_pmtl$Ensembl_ID %in% uniq_ensg_no_na$ensg_id & uniq_pmtl$Approved_Symbol %in% uniq_ensg_no_na$gene_symbol)

#length(mapped_pmtl_no_na$Ensembl_ID) #426
#length(unique(mapped_pmtl_no_na$Ensembl_ID)) #426

#length(mapped_pmtl_no_na$Approved_Symbol) #426
#length(unique(mapped_pmtl_no_na$Approved_Symbol)) #426

#colnames(mapped_pmtl_no_na)


# Remove duplicates (not necessary at this time, but good to have in place)
uniq_mapped_pmtl_no_na <- mapped_pmtl_no_na[!duplicated(mapped_pmtl_no_na[1:length(colnames(mapped_pmtl_no_na))]),]
#colnames(uniq_mapped_pmtl_no_na)

#length(uniq_mapped_pmtl_no_na$Ensembl_ID) #426
#length(unique(uniq_mapped_pmtl_no_na$Ensembl_ID)) #426

#length(uniq_mapped_pmtl_no_na$Approved_Symbol) #426
#length(unique(uniq_mapped_pmtl_no_na$Approved_Symbol)) #426

# Map new pmtl to uniq_ensg_na
mapped_pmtl_na <- uniq_pmtl%>%
  filter(uniq_pmtl$Ensembl_ID %in% uniq_ensg_na$ensg_id & uniq_pmtl$Approved_Symbol %in% uniq_ensg_na$gene_symbol)

#colnames(mapped_pmtl_na)
#length(mapped_pmtl_na$Ensembl_ID) #41
#length(unique(mapped_pmtl_na$Ensembl_ID)) #41

#length(mapped_pmtl_na$Approved_Symbol) #41
#length(unique(mapped_pmtl_na$Approved_Symbol)) #41

#Remove duplicates
uniq_mapped_pmtl_na <- mapped_pmtl_na[!duplicated(mapped_pmtl_na[1:length(colnames(mapped_pmtl_na))]),]
#colnames(uniq_mapped_pmtl_na)

#length(uniq_mapped_pmtl_na$Ensembl_ID) #41
#length(unique(uniq_mapped_pmtl_na$Ensembl_ID)) #41

#length(uniq_mapped_pmtl_na$Approved_Symbol) #41
#length(unique(uniq_mapped_pmtl_na$Approved_Symbol)) #41


# Find pmtl that did not map to existing ensg
no_map_pmtl <- uniq_pmtl %>%
  filter(!Ensembl_ID %in% uniq_mapped_pmtl_no_na$Ensembl_ID & !Ensembl_ID %in% uniq_mapped_pmtl_na$Ensembl_ID)

#colnames(no_map_pmtl)

#length(no_map_pmtl$Ensembl_ID) #4
#length(unique(no_map_pmtl$Ensembl_ID)) #3

#Remove duplicates
uniq_no_map_pmtl <- no_map_pmtl[!duplicated(no_map_pmtl[1:length(colnames(no_map_pmtl))]),]

#colnames(uniq_no_map_pmtl)
#length(uniq_no_map_pmtl$Ensembl_ID) #4
#length(unique(uniq_no_map_pmtl$Ensembl_ID)) #3, this means there is repetion over ID, but gene_symbol is unique


#Recollect ensg that have not been updated with pmtl v1.1
no_chg_ensg_na <- uniq_ensg_na %>%
  filter(!ensg_id %in% uniq_mapped_pmtl_na$Ensembl_ID)

#length(no_chg_ensg_na$ensg_id) #94356
#length(unique(no_chg_ensg_na$ensg_id)) #60789

#Remove duplicates
uniq_no_chg_ensg_na <- no_chg_ensg_na[!duplicated(no_chg_ensg_na[1:length(colnames(no_chg_ensg_na))]),]

#length(uniq_no_chg_ensg_na$ensg_id) #94356
#length(unique(uniq_no_chg_ensg_na$ensg_id)) #60789


no_chg_ensg_no_na <- uniq_ensg_no_na %>%
  filter(!ensg_id %in% uniq_mapped_pmtl_no_na$Ensembl_ID)

#length(no_chg_ensg_no_na$ensg_id) #5
#length(unique(no_chg_ensg_no_na$ensg_id)) #5

  
#colnames(ensg_no_chg)
#length(ensg_no_chg$ensg_id) #94359




# Update column names from rmtl to pmtl
colnames(uniq_no_chg_ensg_na) <- c("ensg_id", "gene_symbol", "pmtl", "version")
colnames(no_chg_ensg_no_na) <- c("ensg_id", "gene_symbol", "pmtl", "version")

colnames(uniq_mapped_pmtl_no_na)  <- c("ensg_id", "gene_symbol", "pmtl", "version")
colnames(uniq_mapped_pmtl_na)  <- c("ensg_id", "gene_symbol", "pmtl", "version")
colnames(uniq_no_map_pmtl)  <- c("ensg_id", "gene_symbol", "pmtl", "version")

# Test
#unique(uniq_no_chg_ensg_na$pmtl)
#unique(no_chg_ensg_no_na$pmtl)

#unique(uniq_no_chg_ensg_na$version)
#unique(no_chg_ensg_no_na$version)


#Update value in pmtl and version columns

no_chg_ensg_no_na$pmtl[no_chg_ensg_no_na$pmtl == "Relevant Molecular Target"] <- "Pediatric Molecular Target"
no_chg_ensg_no_na$version[no_chg_ensg_no_na$version == "RMTL version 1.0"] <- "PMTL version 1.1"


# Add new columns in new arrays
uniq_mapped_pmtl_no_na$pmtl <- "Pediatric Molecular Target"
uniq_mapped_pmtl_na$pmtl <- "Pediatric Molecular Target"
uniq_no_map_pmtl$pmtl <- "Pediatric Molecular Target"

uniq_mapped_pmtl_no_na$version <- "PMTL version 1.1"
uniq_mapped_pmtl_na$version <- "PMTL version 1.1"
uniq_no_map_pmtl$version <- "PMTL version 1.1"


# Final merge
# 426+41+4+94356+5 = 94832
new_ensg_hugo_rmtl_mapping <- data.frame()

new_ensg_hugo_rmtl_mapping <- bind_rows(new_ensg_hugo_rmtl_mapping, 
                                        uniq_mapped_pmtl_no_na, uniq_mapped_pmtl_na, uniq_no_map_pmtl
                                        , uniq_no_chg_ensg_na, no_chg_ensg_no_na)


uniq_new_ensg_hugo_rmtl_mapping <- new_ensg_hugo_rmtl_mapping[!duplicated(new_ensg_hugo_rmtl_mapping[1:length(colnames(new_ensg_hugo_rmtl_mapping))]),]

#length(new_ensg_hugo_rmtl_mapping$ensg_id) #94832
#length(uniq_new_ensg_hugo_rmtl_mapping$ensg_id) #94832

#unique(new_ensg_hugo_rmtl_mapping$pmtl)
#unique(new_ensg_hugo_rmtl_mapping$version)


cmd_mkdir <- paste("mkdir", "results", sep=" ")
system(cmd_mkdir)

#Write to file
filename <- "ensg-hugo-pmtl-mapping"
write.table(uniq_new_ensg_hugo_rmtl_mapping, file=paste("results/",filename,".tsv",sep=""), sep="\t", col.names = T, row.names = F,quote = F)