---
name: Data release
about: Use this to ask a question about or report an issue with the OpenTargets data release files
title: ''
labels: data release
assignees: ''
---

#### Which new datasets are being added with this release?

#### What is the sample breakdown (number of WGS, WXS, RNA-Seq, Panel, Methylation, other)?

#### What module(s) generated any new files to include in the release? Has that module been added to the analysis/README.md, and to CI?

#### Are you aware of any modules impacted by the file(s) change(s)? Describe if the file name is changed.

#### What data file(s) are added/updated/removed in this release?

<!-- See list of files below from current release and update the list as appropriate -->

[**Pre-release files**]
- [ ] histologies-base.tsv
- [ ] cnv-cnvkit.seg.gz
- [ ] cnvkit_with_status.tsv
- [ ] cnv-controlfreec.tsv.gz
- [ ] cnv-consensus-gistic.zip
- [ ] cnv-consensus.seg.gz
- [ ] consensus_seg_with_status.tsv 
- [ ] consensus_wgs_plus_cnvkit_wxs.tsv.gz
- [ ] consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz
- [ ] consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz
- [ ] fusion-arriba.tsv.gz
- [ ] fusion-dgd.tsv.gz
- [ ] fusion-putative-oncogenic.tsv
- [ ] fusion-starfusion.tsv.gz
- [ ] fusion_summary_embryonal_foi.tsv
- [ ] fusion_summary_ependymoma_foi.tsv
- [ ] fusion_summary_ewings_foi.tsv
- [ ] fusion_summary_lgat_foi.tsv
- [ ] snv-consensus-plus-hotspots.maf.tsv.gz
- [ ] snv-dgd.maf.tsv.gz
- [ ] sv-manta.tsv.gz
- [ ] snv-mutation-tmb-all.tsv
- [ ] snv-mutation-tmb-coding.tsv
- [ ] gene-expression-rsem-tpm-collapsed.rds
- [ ] gene-counts-rsem-expected_count-collapsed.rds
- [ ] tcga-gene-expression-rsem-tpm-collapsed.rds
- [ ] tcga-gene-counts-rsem-expected_count-collapsed.rds
- [ ] rna-isoform-expression-rsem-tpm.rds
- [ ] methyl-m-values.rds
- [ ] methyl-cn-values.rds
- [ ] methyl-beta-values.rds
- [ ] independent-specimens.rnaseq.primary-plus.pre-release.tsv
- [ ] independent-specimens.rnaseq.primary.pre-release.tsv
- [ ] independent-specimens.rnaseq.relapse.pre-release.tsv

[**Commit files**]
- [ ] histologies.tsv
- [ ] efo-mondo-map.tsv
- [ ] ensg-hugo-pmtl-mapping.tsv
- [ ] uberon-map-gtex-group.tsv
- [ ] uberon-map-gtex-subgroup.tsv
- [ ] independent-specimens.methyl.primary-plus.eachcohort.tsv
- [ ] independent-specimens.methyl.primary-plus.tsv
- [ ] independent-specimens.methyl.primary.eachcohort.tsv
- [ ] independent-specimens.methyl.primary.tsv
- [ ] independent-specimens.methyl.relapse.eachcohort.tsv
- [ ] independent-specimens.methyl.relapse.tsv
- [ ] independent-specimens.rnaseqpanel.primary-plus.eachcohort.tsv
- [ ] independent-specimens.rnaseqpanel.primary-plus.tsv
- [ ] independent-specimens.rnaseqpanel.primary.eachcohort.tsv
- [ ] independent-specimens.rnaseqpanel.primary.tsv
- [ ] independent-specimens.rnaseqpanel.relapse.eachcohort.tsv
- [ ] independent-specimens.rnaseqpanel.relapse.tsv
- [ ] independent-specimens.wgs.primary-plus.eachcohort.tsv
- [ ] independent-specimens.wgs.primary-plus.tsv
- [ ] independent-specimens.wgs.primary.eachcohort.tsv
- [ ] independent-specimens.wgs.primary.tsv
- [ ] independent-specimens.wgs.relapse.eachcohort.tsv
- [ ] independent-specimens.wgs.relapse.tsv
- [ ] independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wgs.tsv
- [ ] independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wxs.tsv
- [ ] independent-specimens.wgswxspanel.primary-plus.prefer.wgs.tsv
- [ ] independent-specimens.wgswxspanel.primary-plus.prefer.wxs.tsv
- [ ] independent-specimens.wgswxspanel.primary.eachcohort.prefer.wgs.tsv
- [ ] independent-specimens.wgswxspanel.primary.eachcohort.prefer.wxs.tsv
- [ ] independent-specimens.wgswxspanel.primary.prefer.wgs.tsv
- [ ] independent-specimens.wgswxspanel.primary.prefer.wxs.tsv
- [ ] independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wgs.tsv
- [ ] independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wxs.tsv
- [ ] independent-specimens.wgswxspanel.relapse.prefer.wgs.tsv
- [ ] independent-specimens.wgswxspanel.relapse.prefer.wxs.tsv

[**Bed files and sample mapping**]
- [ ] biospecimen_id_to_bed_map.txt
- [ ] ashion_exome_v2_targets_hg38_padded100.bed
- [ ] hg38_strelka.bed
- [ ] intersect_cds_lancet_strelka_mutect_WGS.bed
- [ ] intersect_strelka_mutect_WGS.bed
- [ ] nexterarapidcapture_exome_targetedregions_v1.2_hg38_100.bed
- [ ] S0274956_Padded_HG38.merged.bed
- [ ] S02972011_Covered_hg38_100.bed
- [ ] S04380110_Regions_hg38_100.bed
- [ ] S07604715_100bp_Padded.bed
- [ ] SeqCap_EZ_Exome_v2_Padded_HG38.merged.bed
- [ ] StrexomeLite_hg38_liftover_100bp_padded.bed
- [ ] Strexome_targets_intersect_sorted_padded100.GRCh38.bed
- [ ] TARGET_AML_NBL_WT_SeqVal79_attempt06_AllTracks_HG38_bed_expanded100.bed
- [ ] truseq-exome-targeted-regions-manifest-v1-2_hg38_100.bed
- [ ] wgs_canonical_calling_regions.hg38.bed
- [ ] WGS.hg38.lancet.300bp_padded.bed
- [ ] WGS.hg38.lancet.unpadded.bed
- [ ] WGS.hg38.mutect2.vardict.unpadded.bed
- [ ] WGS.hg38.strelka2.unpadded.bed
- [ ] WGS.hg38.vardict.100bp_padded.bed
- [ ] xgen-exome-research-panel-targets_hg38_ucsc_liftover.100bp_padded.sort.merged.bed

[**File descriptions and notes**]
- [ ] data-files-description.md
- [ ] release-notes.md

#### Any additional notes to add for discussion?

