class: CommandLineTool
cwlVersion: v1.2
id: preprocess_illumina_arrays
doc: |-
  Prepocess raw Illumina Infinium HumanMethylation BeadArrays (450K, and 850k)
  intensities using minfi into usable methylation measurements (Beta and M values)
  and copy number (cn-values) for OpenPedCan.

requirements:
- class: InlineJavascriptRequirement
- class: ShellCommandRequirement
- class: DockerRequirement
  dockerPull: dmiller15/minfi:4.2.0
- class: ResourceRequirement
  ramMin: $(inputs.ram * 1000)
  coresMin: $(inputs.cores)
- class: InitialWorkDirRequirement
  listing:
  - entryname: 01-preprocess-illumina-arrays.R
    writable: false
    entry:
      $include: ../scripts/01-preprocess-illumina-arrays.R
baseCommand: [Rscript, --vanilla, 01-preprocess-illumina-arrays.R]
arguments:
- position: 99
  prefix: ''
  shellQuote: false
  valueFrom: |
    1>&2
inputs:
  input_idats_dir: { type: Directory, loadListing: shallow_listing, inputBinding: { prefix: "--base_dir", position: 1 }, doc: "Directory containing the IDATs to process." }
  controls_present: { type: 'boolean?', inputBinding: { prefix: "--controls_present", position: 1 }, doc: "If set, preprocesses the Illumina methylation array dataset assuming presence of either normal and tumor samples or samples of mutiple cancer groups or both." }
  snp_filter: { type: 'boolean?', inputBinding: { prefix: "--snp_filter", position: 1 }, doc: "If set, drops the probes that contain either a SNP at the CpG interrogation or at the single nucleotide extension." }
  ram: { type: 'int?', default: 32, doc: "GB of RAM to allocate to the task." }
  cores: { type: 'int?', default: 16, doc: "Minimum reserved number of CPU cores for the task." }
outputs:
  beta_values:
    type: File
    outputBinding:
      glob: '*-methyl-beta-values.rds'
  m_values:
    type: File
    outputBinding:
      glob: '*-methyl-m-values.rds'
  cn_values:
    type: File
    outputBinding:
      glob: '*-methyl-cn-values.rds'
