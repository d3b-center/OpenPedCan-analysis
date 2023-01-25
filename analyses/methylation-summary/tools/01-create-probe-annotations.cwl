cwlVersion: v1.2
class: CommandLineTool
id: 01-create-probe-annotations
doc: >-
  Create probe annotations for Illumina infinium methylation arrays

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
      - entryname: 01-create-probe-annotations.R
        entry:
          $include: ../01-create-probe-annotations.R

baseCommand: [mkdir]

arguments:
  - position: 1
    shellQuote: false
    valueFrom: |-
      ./.git
      mkdir -p analyses/methylation-summary/results/
      Rscript 01-create-probe-annotations.R
  - position: 99
    shellQuote: false
    valueFrom: |-
      ${
          if (inputs.output_basename != null) {
            var cmd = " && mv analyses/methylation-summary/results/methyl-probe-annotations.tsv.gz analyses/methylation-summary/results/" + inputs.output_basename + "-methyl-probe-annotations.tsv.gz";
            return cmd;
          }
      }

inputs:
  output_basename: {type: 'string?', doc: "Output basename to prepend to output file"}
  probes_manifest: {type: 'File', inputBinding: {prefix: "--probes_manifest", position: 2}, doc: "The latest Illumina Infinuim array probe manifest with cpg annotation metadata."}
  gencode_gtf: {type: 'File', inputBinding: {prefix: "--gencode_gtf", position: 2}, doc: "The current GENCODE GTF utilized in OpenPedCan analyses modules."}
  ram: {type: 'int?', default: 8, doc: "In GB"}

outputs:
  probe_annotations:
    type: 'File'
    outputBinding:
      glob: analyses/methylation-summary/results/*.tsv.gz
    doc: "Tsv file with methylation probe annotations"