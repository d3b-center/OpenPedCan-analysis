cwlVersion: v1.2
class: CommandLineTool
id: deseq_subsetting
doc: "Run subsetting to create inputs for DESeq2"

requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/deseq2_ot'
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: run-DESeq-Input-Subsetting.R
        entry:
          $include: ../run-DESeq-Input-Subsetting.R

baseCommand: [Rscript]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
     run-DESeq-Input-Subsetting.R --count $(inputs.count_file.path) --hist $(inputs.histology_file.path)

inputs:
  count_file: {type: File, doc: "RSEM count rds file"}
  histology_file: {type: File, doc: "Histology file, should be the base histology file"}

outputs:
  subsetted_histology:
    type: File
    outputBinding:
      glob: histology_subset.tsv
    doc: "Subsetted histology file"
  subsetted_count:
    type: Directory
    outputBinding:
      glob: countData_subset.rds
    doc: "Subsetted count rds file"
  histology_length_file:
    type: File
    outputBinding:
      glob: Hist_Index_limit.txt
    doc: "Text file with count of histology subgroups"
  gtex_length_file:
    type: Directory
    outputBinding:
      glob: GTEx_Index_limit.txt
    doc: "Text file with count of gtex subgroups"
