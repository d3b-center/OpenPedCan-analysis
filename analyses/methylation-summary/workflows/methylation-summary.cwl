cwlVersion: v1.2
class: Workflow
id: methylation-summary

doc: |-
  OpenPedCan Methylation Summary

  Summarize preprocessed `Illumina Infinium HumanMethylation` array measurements produced by the [OpenPedCan methylation-preprocessing module](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/tree/dev/analyses/methylation-preprocessing). 

requirements:
- class: ScatterFeatureRequirement
- class: MultipleInputFeatureRequirement
- class: StepInputExpressionRequirement
- class: SubworkflowFeatureRequirement
- class: InlineJavascriptRequirement

inputs:
  output_basename: {type: 'string?', doc: "Output basename"}
  probes_manifest: {type: 'File', doc: "The latest Illumina Infinuim array probe manifest with cpg annotation metadata."}
  gencode_gtf: {type: 'File', doc: "The current GENCODE GTF utilized in OpenPedCan analyses modules."}
  histologies: {type: 'File', doc: "Histologies file"}
  methyl_matrix: {type: 'File', doc: "OpenPedCan methyl beta-values or m-values matrix file"}
  methyl_values: {type: ['null', {type: enum, name: methyl_values, symbols: ["beta", "m"]}], default: "beta", doc: "OpenPedCan methly matrix values: beta (default) or m"}
  independent_specimens_rna: {type: 'File', doc: "OpenPedCan rnaseq independent biospecimen list file"}
  independent_specimens_methyl: {type: 'File', doc: "OpenPedCan methyl independent biospecimen list file"}
  gene_exp_matrix: {type: 'File', doc: "OpenPedCan gene expression matrix file"}
  isoform_exp_matrix: {type: 'File', doc: "OpenPedCan isoform expression matrix file"}
  efo_mondo_annot: {type: 'File', doc: "OpenPedCan EFO and MONDO annotation file"}
  ram: {type: 'int?', default: 256, doc: "In GB"}

outputs:
  probe_annotations: {type: 'File', outputSource: create-probe-annotations/probe_annotations}
  probe_quantiles: {type: 'File', outputSource: calculate-methyl-quantiles/probe_quantiles}
  methyl_tpm_correlation_gene: {type: 'File', outputSource: methyl-tpm-correlation-gene/methyl_tpm_correlations}
  methyl_tpm_correlation_isoform: {type: 'File', outputSource: methyl-tpm-correlation-isoform/methyl_tpm_correlations}
  tpm_transcript_representation: {type: 'File', outputSource: tpm-transcript-representation/methyl_tpm_transcript_representation}
  summary_table_gene: {type: 'File', outputSource: create-methyl-summary-table-gene/methyl_summary_tsv}
  summary_table_isoform: {type: 'File', outputSource: create-methyl-summary-table-isoform/methyl_summary_tsv}
  summary_table_jsonl_gene: {type: 'File', outputSource: convert-summary-jsonl/gene_methyl_summary_jsonl}
  summary_table_jsonl_isoform: {type: 'File', outputSource: convert-summary-jsonl/isoform_methyl_summary_jsonl}

steps:

  create-probe-annotations:
    run: ../tools/01-create-probe-annotations.cwl
    in:
      output_basename: output_basename
      ram: ram
      probes_manifest: probes_manifest
      gencode_gtf: gencode_gtf
    out: [probe_annotations]

  calculate-methyl-quantiles:
    run: ../tools/02-calculate-methly-quantiles.cwl
    in:
      output_basename: output_basename
      ram: ram
      histologies: histologies
      methyl_matrix: methyl_matrix
      independent_samples: independent_specimens_methyl
      methyl_values: methyl_values
    out: [probe_quantiles]
  
  methyl-tpm-correlation-gene:
    run: ../tools/03-methyl-tpm-correlation.cwl
    in:
      output_basename: output_basename
      ram: ram
      methyl_values: methyl_values
      expression_values:
        valueFrom: "gene"
      histologies: histologies
      independent_specimens_rna: independent_specimens_rna
      independent_specimens_methyl: independent_specimens_methyl
      methyl_matrix: methyl_matrix
      exp_matrix: gene_exp_matrix
      probe_annotations: create-probe-annotations/probe_annotations
    out: [methyl_tpm_correlations]

  methyl-tpm-correlation-isoform:
    run: ../tools/03-methyl-tpm-correlation.cwl
    in:
      output_basename: output_basename
      ram: ram
      methyl_values: methyl_values
      expression_values:
        valueFrom: "isoform"
      histologies: histologies
      independent_specimens_rna: independent_specimens_rna
      independent_specimens_methyl: independent_specimens_methyl
      methyl_matrix: methyl_matrix
      exp_matrix: isoform_exp_matrix
      probe_annotations: create-probe-annotations/probe_annotations
    out: [methyl_tpm_correlations]

  tpm-transcript-representation:
    run: ../tools/04-tpm-transcript-representation.cwl
    in:
      output_basename: output_basename
      ram: ram
      histologies: histologies
      independent_specimens_rna: independent_specimens_rna
      independent_specimens_methyl: independent_specimens_methyl
      isoform_exp_matrix: isoform_exp_matrix
      gene_exp_matrix: gene_exp_matrix
      probe_annotations: create-probe-annotations/probe_annotations
    out: [methyl_tpm_transcript_representation]

  create-methyl-summary-table-gene:
    run: ../tools/05-create-methyl-summary-table.cwl
    in:
      output_basename: output_basename
      ram: ram
      methyl_tpm_corr: methyl-tpm-correlation-gene/methyl_tpm_correlations
      methyl_probe_qtiles: calculate-methyl-quantiles/probe_quantiles
      methyl_probe_annot: create-probe-annotations/probe_annotations
      efo_mondo_annot: efo_mondo_annot
      exp_values:
        valueFrom: "gene"
      methyl_values: methyl_values
    out: [methyl_summary_tsv]

  create-methyl-summary-table-isoform:
    run: ../tools/05-create-methyl-summary-table.cwl
    in:
      output_basename: output_basename
      ram: ram
      methyl_tpm_corr: methyl-tpm-correlation-isoform/methyl_tpm_correlations
      methyl_probe_qtiles: calculate-methyl-quantiles/probe_quantiles
      methyl_probe_annot: create-probe-annotations/probe_annotations
      efo_mondo_annot: efo_mondo_annot
      exp_values:
        valueFrom: "isoform"
      methyl_values: methyl_values
      tpm_transcript_rep: tpm-transcript-representation/methyl_tpm_transcript_representation
    out: [methyl_summary_tsv]

  convert-summary-jsonl:
    run: ../tools/06-methly-summary-tsv2jsonl.cwl
    in:
      output_basename: output_basename
      methyl_values: methyl_values
      gene_summary_file: create-methyl-summary-table-gene/methyl_summary_tsv
      isoform_summary_file: create-methyl-summary-table-isoform/methyl_summary_tsv
    out: [gene_methyl_summary_jsonl, isoform_methyl_summary_jsonl]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 2