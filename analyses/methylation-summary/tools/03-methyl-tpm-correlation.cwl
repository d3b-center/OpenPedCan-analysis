cwlVersion: v1.2
class: CommandLineTool
id: 03-methyl-tpm-correlation
doc: >-
  Calculate representative probe-level correlations between rna-seq (tpm) and methylation (beta/m-vlaues) for patients who have samples in both datasets

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
      - entryname: 03-methyl-tpm-correlation.py
        entry:
          $include: ../03-methyl-tpm-correlation.py

baseCommand: [mkdir]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: |-
      ./.git
      python3 03-methyl-tpm-correlation.py

inputs:
  methyl_values: {type: ['null', {type: enum, name: methyl_values, symbols: ["beta", "m"]}], default: "beta", inputBinding: {prefix: --methyl_values, position: 2}, doc: "OPenPedCan methly matrix values: beta (default) and m"}
  expression_values: {type: ['null', {type: enum, name: expression_values, symbols: ["gene", "isoform"]}], default: "gene", inputBinding: {prefix: --exp_values, position: 2}, doc: "OpenPedCan expression matrix values: gene (default) and isoform"}
  histologies: {type: 'File', inputBinding: {position: 4}, doc: "Histologies file"}
  independent_specimens_rna: {type: 'File', inputBinding: {position: 5}, doc: "OPenPedCan rnaseq independent biospecimen list file"}
  independent_specimens_methyl: {type: 'File', inputBinding: {position: 6}, doc: "OPenPedCan methyl independent biospecimen list file"}
  methyl_matrix: {type: 'File', inputBinding: {position: 7}, doc: "OpenPedCan methyl beta-values or m-values matrix file"}
  exp_matrix: {type: 'File', inputBinding: {position: 8}, doc: "OPenPedCan expression matrix file"}
  probe_annotations: {type: 'File', inputBinding: {position: 9}, doc: "Methylation array probe gencode annotation results file"}
  ram: {type: 'int?', default: 8, doc: "In GB"}

outputs:
  methyl_tmb_correlations:
    type: 'File'
    outputBinding:
      glob: analyses/methylation-summary/results/gene-methyl-probe-*-correlations.tsv.gz
    doc: "Probe-level correlations between methyl beta/m-values RNA-Seq expression tpm values"