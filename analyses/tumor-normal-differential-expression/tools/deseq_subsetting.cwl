cwlVersion: v1.2
class: CommandLineTool
id: deseq_subsetting
doc: "Run subsetting to create inputs for DESeq2"

requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'sangeetashukla/deseq2_cavatica'
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: run-generate-Hist-GTEx-indices-file.R
        entry:
          $include: ../run-generate-Hist-GTEx-indices-file.R

baseCommand: [Rscript]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
     run-generate-Hist-GTEx-indices-file.R --count $(inputs.count_file.path) --hist $(inputs.histology_file.path) --ind_allcohorts $(inputs.ind_allcohorts.path) --ind_eachcohort $(inputs.ind_eachcohort.path)

inputs:
  count_file: {type: File, doc: "RSEM count rds file"}
  histology_file: {type: File, doc: "Histology file, should be the base histology file"}
  ind_allcohorts: {type: File, doc: "Independent specimens for all for cohorts file"}
  ind_eachcohort: {type: File, doc: "Independenct specimens for each cohort file"}

outputs:
  subsetted_histology:
    type: File
    outputBinding:
      glob: histologies_subset.tsv
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
  indices_file:
    type: Directory
    outputBinding:
      glob: indices.txt
    doc: "Text file with pairs of vakues for Hist_i and GTEx_i indices"
