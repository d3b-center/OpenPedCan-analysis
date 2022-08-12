class: CommandLineTool
cwlVersion: v1.2
id: split_cbtn_methylation_manifest
doc: |-
  Splits a given CBTN manifest file by number of lines set in samples_per_split.
  Also generates a file containing the BS_IDs from the manifest.

requirements:
- class: InlineJavascriptRequirement
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: ubuntu:20.04 
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cores)
- class: InitialWorkDirRequirement
  listing:
  - entryname: split_cbtn_methylation_manifest.pl
    writable: false
    entry:
      $include: ../scripts/split_cbtn_methylation_manifest.pl
baseCommand: [perl, split_cbtn_methylation_manifest.pl]
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2
inputs:
  input_manifest: { type: 'File', inputBinding: { position: 1 }, doc: "Input manifest file" }
  samples_per_split: { type: 'int', inputBinding: { position: 2 }, doc: "Number of samples in each split" }
  ram: { type: 'int?', default: 1, doc: "GB of RAM to allocate to the task." }
  cores: { type: 'int?', default: 1, doc: "Minimum reserved number of CPU cores for the task." }
outputs:
  split_manifests:
    type: File[]
    outputBinding:
      glob: '*.csv'
  ids:
    type: File
    outputBinding:
      glob: '*.ids'
