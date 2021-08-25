cwlVersion: v1.2
class: CommandLineTool
id: run_deseq
doc: "Run DESeq2 on subsetted histology and count files"

requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'sangeetashukla/deseq2_cavatica'
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: run-DESeq-analysis.R
        entry:
          $include: ../run-DESeq-analysis.R

baseCommand: [Rscript]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
     run-DESeq-Input-Subsetting.R --counts_file $(inputs.count_file.path)
      --hist_file $(inputs.histology_file.path)
      --tpm_file $(inputs.tpm_file.path)
      --ensg_hugo_file $(inputs.hugo_file.path)
      --efo_mondo_file $(inputs.mondo_file.path)
      --gtex_subgroup_uberon $(inputs.uberon_file.path)
      --HIST_i $(inputs.histology_index)
      --GTEX_i $(inputs.gtex_index)
      -o ./$(inputs.out_dir)

inputs:
  count_file: {type: File, doc: "Subsetted gene counts file"}
  histology_file: {type: File, doc: "Subsetted Histology file, should be the base histology file"}
  tpm_file: {type: File, doc: "TPM counts file"}
  hugo_file: {type: File, doc: "ENSG Hugo codes tsv file"}
  mondo_file: {type: File, doc: "MONDO and EFO codes tsv file"}
  uberon_file: {type: File, doc: "UBERON codes tsv file"}
  histology_index: {type: int, doc: "Index of the histology group to use"}
  gtex_index: {type: int, doc: "Index of the GTEX group to use"}
  out_dir: {type: string, doc: "Name of the output directory"}

outputs:
  results_dir:
    type: Directory
    outputBinding:
      glob: $(inputs.out_dir)
    doc: "Directory of output files"
