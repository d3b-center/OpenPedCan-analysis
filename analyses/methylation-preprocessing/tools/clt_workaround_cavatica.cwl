cwlVersion: v1.2
class: CommandLineTool
id: clt_workaround_cavatica
doc: "Does some work that Cavatica is incapable of doing for some reason"
requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: $(inputs.ram * 1000)
    coresMin: $(inputs.cores)

baseCommand: [echo, complete]

inputs:
  input: { type: 'File' }
  split_input: { type: 'File[]?' }
  ram: { type: 'int?', default: 1, doc: "GB of RAM to allocate to the task." }
  cores: { type: 'int?', default: 1, doc: "Minimum reserved number of CPU cores for the task." }

outputs:
  output:
    type: File[]
    outputBinding:
      outputEval: |
        $(inputs.split_input != null ? inputs.split_input : [inputs.input])
