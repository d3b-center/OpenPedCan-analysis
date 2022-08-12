class: CommandLineTool
cwlVersion: v1.2
id: preprocess_illumina_arrays
doc: |-
  Prepocess raw Illumina Infinium HumanMethylation BeadArrays (27K, 450K, and 850k)
  intensities using minfi into usable methylation measurements (Beta and M values)
  for TARGET normal and tumor samples.

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
  input_manifest: { type: 'File', inputBinding: { prefix: "--metadata_file", position: 1 }, doc: "Input manifest file" }
  preprocess_method:
    type:
    - 'null'
    - name: preprocess_method
      type: enum
      symbols:
      - preprocessQuantile
      - preprocessFunnorm
      - preprocessIllumina
    inputBinding:
      position: 1
      prefix: "--preprocess_method"
    doc: |
      Preprocesses the Illumina methylation array using one of the minfi methods.
  snp_filter: { type: 'boolean?', inputBinding: { prefix: "--snp_filter", position: 1 }, doc: "If set, drops the probes that contain either a SNP at the CpG interrogation or at the single nucleotide extension." }
  ram: { type: 'int?', default: 32, doc: "GB of RAM to allocate to the task." }
  cores: { type: 'int?', default: 16, doc: "Minimum reserved number of CPU cores for the task." }
outputs:
  beta_values:
    type: File
    outputBinding:
      glob: '*beta-values-methylation.tsv'
  m_values:
    type: File
    outputBinding:
      glob: '*m-values-methylation.tsv'

