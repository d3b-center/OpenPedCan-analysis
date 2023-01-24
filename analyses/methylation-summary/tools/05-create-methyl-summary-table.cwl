cwlVersion: v1.2
class: CommandLineTool
id: 05-create-methyl-summary-table
doc: >-
  Create Pediatric OpenTargets methylation summary table

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
      - entryname: 05-create-methyl-summary-table.R
        entry:
          $include: ../05-create-methyl-summary-table.R

baseCommand: [mkdir]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: |-
      ./.git
      analyses/methylation-summary/results/
      Rscript 05-create-methyl-summary-table.R

inputs:
  output_basename: {type: 'string?', doc: "Output basename to prepend to output file"}
  methyl_tpm_corr: {type: 'File', inputBinding: {prefix: --methyl_tpm_corr, position: 2}, doc: "Methyl beta/m-vlaues to tpm-values correlations results file"}
  methyl_probe_qtiles: {type: 'File', inputBinding: {prefix: --methyl_probe_qtiles, position: 2}, doc: "Methyl array probe beta/m-values quantiles results file"}
  methyl_probe_annot: {type: 'File', inputBinding: {prefix: --methyl_probe_annot, position: 2}, doc: "Methyl gencode array probe annotation results file"}
  efo_mondo_annot: {type: 'File', inputBinding: {prefix: --efo_mondo_annot, position: 2}, doc: "OpenPedCan EFO and MONDO annotation file"}
  exp_values: {type: ['null', {type: enum, name: exp_values, symbols: ["gene", "isoform"]}], default: "gene", inputBinding: {prefix: --exp_values, position: 2}, doc: "OpenPedCan expression matrix values: gene (default) or isoform"}
  methyl_values: {type: ['null', {type: enum, name: methyl_values, symbols: ["beta", "m"]}], default: "beta", inputBinding: {prefix: --methyl_values, position: 2}, doc: "OpenPedCan methly matrix values: beta (default) or m"}
  tpm_transcript_rep: {type: 'File?', inputBinding: {prefix: --tpm_transcript_rep, position: 2}, doc: "RNA-Seq expression (tpm) gene isoform (transcript) representation results file"}
  ram: {type: 'int?', default: 8, doc: "In GB"}

outputs:
  methyl_summary_rds:
    type: 'File'
    outputBinding:
      glob: analyses/methylation-summary/results/*.rds
      outputEval: |
        ${
          if (inputs.output_basename != null) {
            self[0].basename = inputs.output_basename + '.' + self[0].basename
          }
          return self[0]
        }
    doc: "Methylation summary table RDS file"
    
  methyl_summary_tsv:
    type: 'File'
    outputBinding:
      glob: analyses/methylation-summary/results/*.tsv.gz
      outputEval: |
        ${
          if (inputs.output_basename != null) {
            self[0].basename = inputs.output_basename + '.' + self[0].basename
          }
          return self[0]
        }
    doc: "Methylation summary table tsv file"