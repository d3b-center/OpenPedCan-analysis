class: CommandLineTool
cwlVersion: v1.2
id: merge_methylation_outputs
doc: |-
  Takes one or more methylation outputs and merges them using awk.

requirements:
- class: InlineJavascriptRequirement
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: ubuntu:20.04 
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cores)
baseCommand: []
arguments:
- position: 1
  prefix: ''
  shellQuote: false
  valueFrom: |
    awk 'FNR==1 && NR!=1 {(/^<header>/) getline;} 1 {print}' 
inputs:
  input_methlyation_files: { type: 'File[]', inputBinding: { position: 1 }, doc: "Input methylation files" }
  output_filename: { type: 'string', inputBinding: { prefix: '>', shellQuote: false, position: 3 }, doc: "Name of the output file" }
  ram: { type: 'int?', default: 1, doc: "GB of RAM to allocate to the task." }
  cores: { type: 'int?', default: 1, doc: "Minimum reserved number of CPU cores for the task." }
outputs:
  output:
    type: File
    outputBinding:
      glob: $(inputs.output_filename)
