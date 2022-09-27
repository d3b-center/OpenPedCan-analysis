cwlVersion: v1.2
class: Workflow
id: opentargets-methylation-array-workflow
label: OpenTargets Methylation Array Workflow
doc: |
  Preprocess probe hybridization intensity values of selected methylated and
  unmethylated cytosine (CpG) loci into usable methylation measurements for the
  [Pediatric Open Targets, OPenPedCan-analysis](https://github.com/PediatricOpenTargets/OpenPedCan-analysis)
  raw DNA methylation array datasets.

  This workflow is used to efficiently handle a large number of IDAT files that
  have been provided with a manifest (either from TARGET or CBTN). The workflow
  will:
  1. using perl and linux split, optionally split the manifest file by the `samples_per_split` input
  2. for each manifest, run the 01-preprocess-illumina-arrays.R module
  3. merge the beta and m value outputs from the scattered module runs
  4. return the merged files to the user
requirements:
- class: InlineJavascriptRequirement
- class: MultipleInputFeatureRequirement
- class: ScatterFeatureRequirement
- class: StepInputExpressionRequirement
inputs:
  # Required Inputs
  input_manifest: { type: 'File', doc: "Input manifest file" }
  input_idats_dir: { type: Directory, doc: "Directory containing the IDATs to process." }
  output_basename: { type: 'string', doc: "String to use as basename for output filenames." }

  # Optional Arguments
  samples_per_split: { type: 'int?', doc: "ONLY FOR CBTN MANIFESTS! Number of samples in each split. Leave empty if you do not wish to split the manifest." }
  preprocess_method:
    type:
    - 'null'
    - name: preprocess_method
      type: enum
      symbols:
      - preprocessQuantile
      - preprocessFunnorm
      - preprocessIllumina
    doc: |
      Preprocesses the Illumina methylation array using one of the minfi methods.
  snp_filter: { type: 'boolean?', doc: "If set, drops the probes that contain either a SNP at the CpG interrogation or at the single nucleotide extension." }

  # Resource Control
  preprocess_methylation_array_cores: { type: 'int?', doc: "Cores to give to the preprocess_methylation_arrays step" }
  preprocess_methylation_array_ram: { type: 'int?', doc: "GB of RAM to give to the preprocess_methylation_arrays step" }
outputs:
  methylation_beta_values: { type: File, outputSource: merge_methylation_beta_values/output, doc: "" }
  methylation_m_values: { type: File, outputSource: merge_methylation_m_values/output, doc: "" }
steps:
  split_manifest:
    run: ../tools/split_cbtn_methylation_manifest.cwl
    when: $(inputs.samples_per_split != null)
    in:
      input_manifest: input_manifest
      samples_per_split: samples_per_split
    out: [ids, split_manifests]
  workaround_cavatica:
    run: ../tools/clt_workaround_cavatica.cwl
    in:
      input: input_manifest
      split_input: split_manifest/split_manifests
    out: [output]
  preprocess_methylation_arrays:
    run: ../tools/preprocess_illumina_arrays.cwl
    scatter: input_manifest
    in:
      input_manifest: workaround_cavatica/output
      input_idats_dir: input_idats_dir
      preprocess_method: preprocess_method
      snp_filter: snp_filter
      cores: preprocess_methylation_array_cores
      ram: preprocess_methylation_array_ram
    out: [beta_values, m_values]
  merge_methylation_beta_values:
    run: ../tools/merge_methylation_outputs.cwl
    in:
      input_methlyation_files: preprocess_methylation_arrays/beta_values
      output_filename:
        source: output_basename
        valueFrom: $(self).beta-values-methylation.tsv
    out: [output]
  merge_methylation_m_values:
    run: ../tools/merge_methylation_outputs.cwl
    in:
      input_methlyation_files: preprocess_methylation_arrays/m_values
      output_filename:
        source: output_basename
        valueFrom: $(self).m-values-methylation.tsv
    out: [output]

$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: "sbg:maxNumberOfParallelInstances"
  value: 2
