cwlVersion: v1.2
class: Workflow
id: run_deseq2_analysis
label: Run DESeq2 Analysis comparing samples in cancer histology groups to GTEX
doc: |-
  # Run DESeq2 Analysis comparing samples in cancer histology groups to GTEX

requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:
  output_basename: {type: string, doc: "Output basename for workflow output files"}
  gene_count_file: {type: File, doc: "RSEM gene counts rds file"}
  histology_file: {type: File, doc: "Histology file, should be the base histology file"}
  tpm_file: {type: File, doc: "TPM counts rds file"}
  hugo_file: {type: File, doc: "ENSG Hugo codes tsv file"}
  mondo_file: {type: File, doc: "MONDO and EFO codes tsv file"}
  uberon_file: {type: File, doc: "UBERON codes tsv file"}
  ind_allcohorts: {type: File, doc: "Independent specimens for all cohorts file"}
  ind_eachcohort: {type: File, doc: "Independent specimens for each cohort file"}
  ram: {type: 'int?', default: 32, doc: "In GB"}
  cpus: {type: 'int?', default: 4, doc: "Number of CPUs to request"}
  hist_max_index_test: {type: 'int?', doc: "Maximum number of histology groups to use for testing, this overrides the number of histology groups from the subsetting tool."}
  gtex_max_index_test: {type: 'int?', doc: "Maximum number of gtex groups to use for testing, this overrides the number of gtex groups from the subsetting tool."}

outputs:
  output_tsv: {type: File, outputSource: combine_output_files/combined_tsv}
  output_jsonl: {type: File, outputSource: combine_output_files/combined_jsonl}
  output_rds: {type: File, outputSource: convert_tsv_to_rds/merged_rds}

steps:

  subset_inputs:
    run: ../tools/deseq_subsetting.cwl
    in:
      count_file: gene_count_file
      histology_file: histology_file
      ind_allcohorts: ind_allcohorts
      ind_eachcohort: ind_eachcohort
    out: [subsetted_histology, subsetted_count, histology_length_file, gtex_length_file]

  build_hist_array:
    run: ../tools/build_index_array.cwl
    in:
      index_max_file: subset_inputs/histology_length_file
      test_maximum: hist_max_index_test
    out: [index_array]

  build_gtex_array:
    run: ../tools/build_index_array.cwl
    in:
      index_max_file: subset_inputs/gtex_length_file
      test_maximum: gtex_max_index_test
    out: [index_array]

  run_deseq2:
    run: ../tools/run_deseq.cwl
    scatter: [histology_index, gtex_index]
    scatterMethod: flat_crossproduct
    in:
      count_file: subset_inputs/subsetted_count
      histology_file: subset_inputs/subsetted_histology
      tpm_file: tpm_file
      hugo_file: hugo_file
      mondo_file: mondo_file
      uberon_file: uberon_file
      ind_allcohorts: ind_allcohorts
      ind_eachcohort: ind_eachcohort
      histology_index: build_hist_array/index_array
      gtex_index: build_gtex_array/index_array
      out_dir: output_basename
      ram: ram
      cpus: cpus
    out: [results_dir]

  combine_output_files:
    run: ../tools/combine_output_files.cwl
    in:
      results_dirs: run_deseq2/results_dir
      output_basename: output_basename
    out:
      [combined_tsv, combined_jsonl]

  convert_tsv_to_rds:
    run: ../tools/convert_tsv_to_rds.cwl
    in:
      combined_tsv: combine_output_files/combined_tsv
      output_basename: output_basename
    out: [merged_rds]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 80
  - class: 'sbg:AWSInstanceType'
    value: r5.24xlarge
