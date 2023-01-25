cwlVersion: v1.2
class: CommandLineTool
id: 04-tpm-transcript-representation
doc: >-
  Calculate rna-seq expression (tpm) gene isoform (transcript) representation for patients who have samples in both rna-seq and methylation datasets

requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: "alexsickler/open-pedcan:latest"
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: ${return inputs.ram * 1000}
    coresMin: 4
  - class: LoadListingRequirement
    loadListing: shallow_listing
  - class: InitialWorkDirRequirement
    listing:
      - entryname: 04-tpm-transcript-representation.py
        entry:
          $include: ../04-tpm-transcript-representation.py

baseCommand: [mkdir]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: |-
      ./.git
      mkdir -p ./.git/objects
      mkdir -p ./.git/refs
      mkdir -p analyses/methylation-summary/results
      python3 04-tpm-transcript-representation.py

inputs:
  output_basename: {type: 'string?', doc: "Output basename to prepend to output file"}
  histologies: {type: 'File', inputBinding: {position: 2}, doc: "Histologies file"}
  independent_specimens_rna: {type: 'File', inputBinding: {position: 3}, doc: "OpenPedCan rnaseq independent biospecimen list file"}
  independent_specimens_methyl: {type: 'File', inputBinding: {position: 4}, doc: "OpenPedCan methyl independent biospecimen list file"}
  methyl_matrix: {type: 'File', inputBinding: {position: 5}, doc: "OpenPedCan methyl beta-values or m-values matrix file"}
  gene_exp_matrix: {type: 'File', inputBinding: {position: 6}, doc: "OpenPedCan gene expression matrix file"}
  isoform_exp_matrix: {type: 'File', inputBinding: {position: 7}, doc: "OpenPedCan isoform expression matrix file"}
  probe_annotations: {type: 'File', inputBinding: {position: 8}, doc: "Methylation array probe gencode annotation results file"}
  ram: {type: 'int?', default: 8, doc: "In GB"}

outputs:
  methyl_tpm_transcript_representation:
    type: 'File'
    outputBinding:
      glob: analyses/methylation-summary/results/methyl-tpm-transcript-representation.tsv.gz
      outputEval: |
        ${
          if (inputs.output_basename != null) {
            self[0].basename = inputs.output_basename + '.' + self[0].basename
          }
          return self[0]
        }
    doc: "Rna-seq expression (tpm) gene isoform (transcript) representation values"