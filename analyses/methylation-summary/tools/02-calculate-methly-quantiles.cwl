cwlVersion: v1.2
class: CommandLineTool
id: 02-calculate-methly-quantiles
doc: >-
  Calculate probe-level methylation values quantiles for all histologies (cancer types)

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
      - entryname: 02-calculate-methly-quantiles.R
        entry:
          $include: ../02-calculate-methly-quantiles.R

baseCommand: [mkdir]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: |-
      ./.git
      mkdir -p analyses/methylation-summary/results/
      Rscript 02-calculate-methly-quantiles.R
  - position: 99
    shellQuote: false
    valueFrom: |-
      ${
          if (inputs.output_basename != null) {
            var cmd = " && cd analyses/methylation-summary/results/ && ";
            cmd += "for f in *; do mv \"$f\" \"" + inputs.output_basename + "-$f \"; done";
            return cmd;
          }
      }

inputs:
  output_basename: {type: 'string?', doc: "Output basename to prepend to output file"}
  histologies: {type: 'File', inputBinding: {prefix: --histologies, position: 2}, doc: "Histologies file"}
  methyl_matrix: {type: 'File', inputBinding: {prefix: --methyl_matrix, position: 2}, doc: "OpenPedCan methyl beta-values or m-values matrix file"}
  independent_samples: {type: 'File', inputBinding: {prefix: --independent_samples, position: 2}, doc: "OpenPedCan methyl independent biospecimen list file"}
  methyl_values: {type: ['null', {type: enum, name: methyl_values, symbols: ["beta", "m"]}], default: "beta", inputBinding: {prefix: --methyl_values, position: 2}, doc: "OpenPedCan methly matrix values: beta (default) or m"}
  ram: {type: 'int?', default: 8, doc: "In GB"}

outputs:
  probe_quantiles:
    type: 'File'
    outputBinding:
      glob: analyses/methylation-summary/results/*.tsv.gz
    doc: "Probe-level methyl values quantiles"