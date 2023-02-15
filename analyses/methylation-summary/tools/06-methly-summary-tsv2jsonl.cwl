cwlVersion: v1.2
class: CommandLineTool
id: 06-methly-summary-tsv2jsonl
doc: >-
  Convert methylation summary TSV table to JSONL

requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: "alexsickler/opc_methylation_summary:1.0.0"
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
      mkdir -p ./.git/objects
      mkdir -p ./.git/refs
      touch ./.git/HEAD
      mkdir -p analyses/methylation-summary/results
      python3 06-methly-summary-tsv2jsonl.py
  - position: 99
    shellQuote: false
    valueFrom: |-
      ${
          if (inputs.output_basename != null) {
            var cmd = " && mv analyses/methylation-summary/results/gene-methyl-" + inputs.methyl_values + "-values-summary.jsonl.gz analyses/methylation-summary/results/" + inputs.output_basename + "gene-methyl-" + inputs.methyl_values + "-values-summary.jsonl.gz";
            var cmd = " && mv analyses/methylation-summary/results/isoform-methyl-" + inputs.methyl_values + "-values-summary.jsonl.gz analyses/methylation-summary/results/" + inputs.output_basename + "isoform-methyl-" + inputs.methyl_values + "-values-summary.jsonl.gz";
            return cmd;
          }
      }

inputs:
  output_basename: {type: 'string?', doc: "Output basename to prepend to output file"}
  methyl_values: {type: ['null', {type: enum, name: methyl_values, symbols: ["beta", "m"]}], default: "beta", inputBinding: {prefix: --methyl_values, position: 2}, doc: "OpenPedCan methly matrix values: beta (default) or m"}
  gene_summary_file: {type: 'File', inputBinding: {position: 3}, doc: "Gene-level methyl summary TSV file"}
  isoform_summary_file: {type: 'File', inputBinding: {position: 4}, doc: "Isoform-level methyl summary TSV file"}
  ram: {type: 'int?', default: 8, doc: "In GB"}

outputs:
  gene_methyl_summary_jsonl:
    type: 'File'
    outputBinding:
      glob: analyses/methylation-summary/results/*gene*.jsonl
    doc: "Methylation summary table jsonl file"

  isoform_methyl_summary_jsonl:
    type: 'File'
    outputBinding:
      glob: analyses/methylation-summary/results/*isoform*.jsonl
    doc: "Methylation summary table jsonl file"