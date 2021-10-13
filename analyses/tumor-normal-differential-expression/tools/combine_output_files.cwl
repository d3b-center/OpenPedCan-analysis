cwlVersion: v1.0
class: CommandLineTool
id: combine_output_files
doc: "Combine output jsonl and tsv files into one set of merged json and tsv files."

requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/d3b-bixu/ubuntu:18.04'
  - class: InitialWorkDirRequirement
    listing: [$(inputs.results_dirs)]

baseCommand: []

arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      cat ./*/*.jsonl > $(inputs.output_basename).jsonl &&
      awk '(NR == 1) || (FNR > 1)' ./*/*.tsv > $(inputs.output_basename).tsv

inputs:
  results_dirs: {type: 'Directory[]', doc: "Deseq2 output directories"}
  output_basename: {type: string, doc: "Output files basename"}

outputs:
  combined_tsv:
    type: File
    outputBinding:
      glob: '*.tsv'
    doc: "Output combined tsv file."
  combined_jsonl:
    type: File
    outputBinding:
      glob: '*.jsonl'
    doc: "Output combined jsonl file."
