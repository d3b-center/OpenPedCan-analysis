cwlVersion: v1.2
class: CommandLineTool
id: 06-methly-summary-tsv2jsonl
doc: >-
  Convert methylation summary TSV table to JSONL

requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: "pgc-images.sbgenomics.com/d3b-bixu/open-pedcan:latest"
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: ${return inputs.ram * 1000}
    coresMin: 4
  - class: LoadListingRequirement
    loadListing: shallow_listing
  - class: InitialWorkDirRequirement
    listing:
      - entryname: 06-methly-summary-tsv2jsonl.py
        entry:
          $include: ../06-methly-summary-tsv2jsonl.py

baseCommand: [mkdir]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: |-
      ./.git
      mkdir analyses/methylation-summary/results
      python3 06-methly-summary-tsv2jsonl.py

inputs:
  output_basename: {type: 'string?', doc: "Output basename to prepend to output file"}
  methyl_values: {type: ['null', {type: enum, name: methyl_values, symbols: ["beta", "m"]}], default: "beta", inputBinding: {prefix: --methyl_values, position: 2}, doc: "OpenPedCan methly matrix values: beta (default) or m"}
  gene_summary_file: {type: 'File', inputBinding: {position: 3}, doc: "Gene-level methyl summary TSV file"}
  isoform_summary_file: {type: 'File', inputBinding: {position: 4}, doc: "Isoform-level methyl summary TSV file"}
  ram: {type: 'int?', default: 8, doc: "In GB"}

outputs:
  methyl_summary_jsonl:
    type: 'File'
    outputBinding:
      glob: analyses/methylation-summary/results/*.jsonl
      outputEval: |
        ${
          if (inputs.output_basename != null) {
            self[0].basename = inputs.output_basename + '.' + self[0].basename
          }
          return self[0]
        }
    doc: "Methylation summary table jsonl file"