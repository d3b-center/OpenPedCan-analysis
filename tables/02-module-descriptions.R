library(readr)
library(dplyr)
library(stringr)
library(openxlsx)

## set directories
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))
analysis_dir <- file.path(root_dir, "analyses")
output_dir <- file.path(root_dir, "tables", "results")

output_file <- file.path(output_dir, "SuppTable2-Modules.xlsx")

# 1. Read the markdown file
md_lines <- read_lines(file.path(analysis_dir, "README.md"))

# 2. Identify the table lines (look for pipes '|' and at least one row of dashes)
table_start <- which(str_detect(md_lines, "^\\|.*\\|"))[1]

# 3. Extract table lines
# Continue until non-table line or end of file
table_lines <- md_lines[table_start:length(md_lines)]
end_of_table <- which(!str_detect(table_lines, "^\\|"))[1]
if (!is.na(end_of_table)) {
  table_lines <- table_lines[1:(end_of_table - 1)]
}

# 4. Convert markdown table to data frame
# Remove leading/trailing whitespace and split by '|'
table_clean <- table_lines %>%
  str_trim() %>%
  str_remove_all("^\\||\\|$") %>%
  str_split_fixed("\\|", n = Inf)

# 5. Use the first row as column names and skip the second (separator row)
# Skip both the header and separator when creating data rows
df <- as.data.frame(table_clean[-c(1, 2), ], stringsAsFactors = FALSE)
colnames(df) <- table_clean[1, ]

# 6. Write first 5 columns to excel for supplemental table
openxlsx::write.xlsx(df[,1:5], output_file)
