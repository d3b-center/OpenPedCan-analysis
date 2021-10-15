cwlVersion: v1.2
class: CommandLineTool
id: tsv_to_rds
doc: "Convert merged TSV file to RDS format"

requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'sangeetashukla/deseq2_cavatica'
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: convert_tsv_to_rds.R
        entry:
          $include: ../convert_tsv_to_rds.R

baseCommand: [Rscript]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
     convert_tsv_to_rds.R --tsv_file $(inputs.combined_tsv.path)

inputs:
  combined_tsv: {type: 'File', doc: "Merged results from all comparisons"}

outputs:
  merged_rds:
    type: File
    outputBinding:
      glob: deseq_all_comparisons.rds
    doc: "Merged RDS file"
