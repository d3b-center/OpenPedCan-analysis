# release notes

## current release
- release date: 2023-04-XX
- status: available
- overview of changes (See [PR XXX](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/pull/) for additional details):
  - This release adds the following data: 
    - 744 methylation array data samples
      - 728 PBTA samples (17 normal, 711 tumor)
      - 16 TARGET samples (6 normal, 10 tumor)
    - 1264 RNA-seq samples
      - 1264 PBTA samples (3 normal, 1261 tumor)
    - 2759 WGS/WXS samples
      - 3 Kentucky samples (3 normal)
      - 2441 PBTA WGS samples (1171 normal, 1270 tumor)
      - 315 PBTA WXS samples (160 normal, 155 tumor)
 
  - Updated data to use GENCODE v39 GDC
    - Update gene_match module GENCODE versions [Ticket 400](https://github.com/PediatricOpenTargets/ticket-tracker/issues/400)
    - Update analysis modules to use GENCODE 39 [Tikcet 422](https://github.com/PediatricOpenTargets/ticket-tracker/issues/422) 
    - Update analysis modules to use GENCODE 39 [Tikcet 423](https://github.com/PediatricOpenTargets/ticket-tracker/issues/423) 
    - Include updated gene symbol to gene_match module PMTL table [Ticket 472](https://github.com/PediatricOpenTargets/ticket-tracker/issues/472)
    - Update EPN analysis to pull new gene names using GENCODE v39 symbols [Ticket 485](https://github.com/PediatricOpenTargets/ticket-tracker/issues/485)
    - Fusion summary to use new gene symbols from GENCODE v39 [Ticket 486](https://github.com/PediatricOpenTargets/ticket-tracker/issues/486)
    - HGG subtyping to include GENCODE v39 gene symbols [Ticket 487](https://github.com/PediatricOpenTargets/ticket-tracker/issues/487)
    - LGG subtyping to take in new H3 gene symbols for GENCODE v39 update [Ticket 488](https://github.com/PediatricOpenTargets/ticket-tracker/issues/488)
    - Update DGD fusion file to match GENCODE v39 symbols + run FusionAnnotator on it [Ticket 490](https://github.com/PediatricOpenTargets/ticket-tracker/issues/490)
    - Harmonize PBTA X01 cohort using GENCODE v39 [Ticket 427](https://github.com/PediatricOpenTargets/ticket-tracker/issues/427)
    - Harmonize TARGET and GMKF cohorts using GENCODE v39 [Ticket 428](https://github.com/PediatricOpenTargets/ticket-tracker/issues/428)
    - Remap TCGA expression matrix to GENCODE v39 [Ticket 521](https://github.com/PediatricOpenTargets/ticket-tracker/issues/521)
    - Remap GTEx TPM matrix to GENCODE v39 gene symbols [Ticket 522](https://github.com/PediatricOpenTargets/ticket-tracker/issues/522)
 
  - Update histologies file - key changes noted here (other tickets can be found in OpenPedCan repo)
    - Corrected diagnosis for sample `7316-356` [Ticket 366](https://github.com/PediatricOpenTargets/ticket-tracker/issues/366)
    - Update histologies with the correct MYCN status from TARGET and GMKF clinical files [Ticket 415](https://github.com/PediatricOpenTargets/ticket-tracker/issues/415)
    - Add previously excluded methylation samples to the histologies file [Ticket 421](https://github.com/PediatricOpenTargets/ticket-tracker/issues/421)
    - Updated GTEx base histologies file to inclue `gtex-group` and `getx_subgroup` columns [Ticket 435](https://github.com/PediatricOpenTargets/ticket-tracker/issues/435)
    - Examine the latest base adapt histologies for updates [Ticket 454](https://github.com/PediatricOpenTargets/ticket-tracker/issues/454)
    - Create bixu-generated fields for v12 release [Ticket 481](https://github.com/PediatricOpenTargets/ticket-tracker/issues/481)
    - v12 WGS germline sex estimate [Ticket 492](https://github.com/PediatricOpenTargets/ticket-tracker/issues/492)
  - Updates to help with creation and QC of histologies file
    - Creat automated workflow for `histologies-base.tsv` [Ticket 399](https://github.com/PediatricOpenTargets/ticket-tracker/issues/399)
    - Histologies QC to check germline sex estimate [Ticket 426](https://github.com/PediatricOpenTargets/ticket-tracker/issues/426)
    - Create data warehous dbt tables for OpenTargets histologies mapping files [Ticket 445](https://github.com/PediatricOpenTargets/ticket-tracker/issues/445)
    - Create PPTC PDX study base histologies file [Ticket 479](https://github.com/PediatricOpenTargets/ticket-tracker/issues/479)
    - Create chordoma base histologies file [Ticket 484](https://github.com/PediatricOpenTargets/ticket-tracker/issues/484)
 
  - Molecular subtyping updates
    - Update EPN fusions [Ticket 287](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/pull/287)
    - Update gliomatosis cerebri term in LGAT subtyping [Ticket 358](https://github.com/PediatricOpenTargets/ticket-tracker/issues/358)
    - Manually add BS_YKEK4YWT fusion to DGD fusion file [Ticket 392](https://github.com/PediatricOpenTargets/ticket-tracker/issues/392)
    - fusion-summary: modify ependymoma gene pairs [Ticket 440](https://github.com/PediatricOpenTargets/ticket-tracker/issues/440)
    - Update Ependymoma subtyping to add K28M --> PFA [Ticket 424](https://github.com/PediatricOpenTargets/ticket-tracker/issues/424)
    - Ependymoma subyping - add spinal EPN type [Ticket 425](https://github.com/PediatricOpenTargets/ticket-tracker/issues/425)
    - Ependymoma subtyping-- rename EPN, ST RELA subgroup to EPN, ST ZFTA [Ticket 439](https://github.com/PediatricOpenTargets/ticket-tracker/issues/439)
    - Neuroblastoma (NBL) molecular subtyping into MYCN amplified or MYCN non-amplified [Ticket 417](https://github.com/PediatricOpenTargets/ticket-tracker/issues/417)
    - Remove manual override of patient ID "PT_7E3V3JFX" subtying [Ticket 449](https://github.com/PediatricOpenTargets/ticket-tracker/issues/449)
    - Update EPN subtyping fusion pairs to include the `YAP1--MAML2` fusion [Ticket 451](https://github.com/PediatricOpenTargets/ticket-tracker/issues/451)
    - Add Infant-Type Hemispheric Glioma to HGG subtyping module [Ticket 474](https://github.com/PediatricOpenTargets/ticket-tracker/issues/474)
    - Incorrect subtypes [Ticket 489](https://github.com/PediatricOpenTargets/ticket-tracker/issues/489)
    - Update ATRT subtyping to assign samples to one of 3 subtypes, `ATRT, MYC`, `ATRT, SHH`, or `ATRT, TYR` [Ticket 496](https://github.com/PediatricOpenTargets/ticket-tracker/issues/496)
    - Update modules using manta file for v12 release due to column name changes [Ticket](https://github.com/PediatricOpenTargets/ticket-tracker/issues/499)
    - Update mol subtyping integrate to include ATRT + NBL [Ticket 504](https://github.com/PediatricOpenTargets/ticket-tracker/issues/504)
    - Update embryonal subtyping TTYH1 fusion search [Ticket 531](https://github.com/PediatricOpenTargets/ticket-tracker/issues/531)

  - Update EFO MONDO file 
    - Updated EFO/MONDO mapping using OT custom EFO ontology [Ticket 418](https://github.com/PediatricOpenTargets/ticket-tracker/issues/418) and [Ticket 420](https://github.com/PediatricOpenTargets/ticket-tracker/issues/420) 
 
  - methylation updates
    - Update methylation summary module [Ticket 371](https://github.com/PediatricOpenTargets/ticket-tracker/issues/371) 
    - Add v12b6 CBTN methylation classifier results to data warehouse [Ticket 391](https://github.com/PediatricOpenTargets/ticket-tracker/issues/391)
    - Updated methylation arrays pre-processing module [Ticket 404](https://github.com/PediatricOpenTargets/ticket-tracker/issues/404)
    - Preprocess CBTN methylation arrays [Ticket 430](https://github.com/PediatricOpenTargets/ticket-tracker/issues/430)
    - Update methylation subtyping information for D3b warehouse import [Ticket 434](https://github.com/PediatricOpenTargets/ticket-tracker/issues/434)
    - Create methylation summary tables for display and download on the MTP portal [Ticket 456](https://github.com/PediatricOpenTargets/ticket-tracker/issues/456) and [Ticket 478](https://github.com/PediatricOpenTargets/ticket-tracker/issues/456)
  
  - CHOP Panel data updates
    - Update DGD MAF with updated BS IDs for v12 OPC release [Ticket 406](https://github.com/PediatricOpenTargets/ticket-tracker/issues/406)
    - KMT2C 100% Mutation Frequency in DGD Samples [Ticket 416](https://github.com/PediatricOpenTargets/ticket-tracker/issues/416)
    - Reprocess DGD panel data [Ticket 429](https://github.com/PediatricOpenTargets/ticket-tracker/issues/429)
  
  - v12 data release updates
    - Update gene_match module for v12 data release [Ticket 525](https://github.com/PediatricOpenTargets/ticket-tracker/issues/525)
    - Updated efo-mondo-mapping module for v12 data release [Ticket 526](https://github.com/PediatricOpenTargets/ticket-tracker/issues/526)
    - Update cnv-frequencies tables for v12 data release [Ticket 527](https://github.com/PediatricOpenTargets/ticket-tracker/issues/527)
    - Update fusion-frequencies tables for v12 data release [Ticket 528](https://github.com/PediatricOpenTargets/ticket-tracker/issues/528)
    - Update snv-frequencies tables for v12  data release [Ticket 529](https://github.com/PediatricOpenTargets/ticket-tracker/issues/529)
    - Update rna-seq-expression-summary-stats tables for v12 data release [Ticket 530](https://github.com/PediatricOpenTargets/ticket-tracker/issues/530)
  
  - other changes
    - Bix Dev PedcbioPortal Support: Update PPTC study reference [Ticket 375](https://github.com/PediatricOpenTargets/ticket-tracker/issues/375)
    - Remove metastatic secondary tumors from independent specimen lists [Ticket 383](https://github.com/PediatricOpenTargets/ticket-tracker/issues/383)
    - Update MTP tables filtering module [Ticket 433](https://github.com/PediatricOpenTargets/ticket-tracker/issues/433)
    - Resolved duplicate rows/different values in CNVkit consensus file [Ticket 436](https://github.com/PediatricOpenTargets/ticket-tracker/issues/436)
    - Update focal cn prep to resolve multiple locus status calls [Ticket 437](https://github.com/PediatricOpenTargets/ticket-tracker/issues/437)
    - Updated analyses modules to remove PMTL annotation process [Ticket 447](https://github.com/PediatricOpenTargets/ticket-tracker/issues/447)
    - Updated data pre-release QC module [Ticket 450](https://github.com/PediatricOpenTargets/ticket-tracker/issues/450)
    - Creat merged rMATs matrix for v12 release [Ticket 480](https://github.com/PediatricOpenTargets/ticket-tracker/issues/480)
    - Create Open Targets Platform approved targets and diseases identifiers [Ticket 491](https://github.com/PediatricOpenTargets/ticket-tracker/issues/491)
    - Update CI testing data to include methylation matrices [Ticket 493](https://github.com/PediatricOpenTargets/ticket-tracker/issues/493)
    - Update driver gene list [Ticket 494](https://github.com/PediatricOpenTargets/ticket-tracker/issues/494)
    - Fusion filtering (annoFuse) bug [Ticket 503](https://github.com/PediatricOpenTargets/ticket-tracker/issues/503)
    - Modify artifact column selection in fusion filtering for GTEx [Ticket 507](https://github.com/PediatricOpenTargets/ticket-tracker/issues/507)
    - Updated MTP tables datatypeId column [Ticket 510](https://github.com/PediatricOpenTargets/ticket-tracker/issues/510)

```
v12
├── 20038D-17Q6-01.regions.100bp_padded.bed
├── S0274956_Padded_HG38.merged.bed
├── S02972011_Covered_hg38_100.bed
├── S04380110_Regions_hg38_100.bed
├── S07604715_100bp_Padded.bed
├── SeqCap_EZ_Exome_v2_Padded_HG38.merged.bed
├── StrexomeLite_hg38_liftover_100bp_padded.bed
├── Strexome_targets_intersect_sorted_padded100.GRCh38.bed
├── TARGET_AML_NBL_WT_SeqVal79_attempt06_AllTracks_HG38_bed_expanded100.bed
├── UCSC_hg19-GRCh37_Ensembl2RefSeq.tsv
├── WGS.hg38.lancet.300bp_padded.bed
├── WGS.hg38.lancet.unpadded.bed
├── WGS.hg38.mutect2.vardict.unpadded.bed
├── WGS.hg38.strelka2.unpadded.bed
├── WGS.hg38.vardict.100bp_padded.bed
├── agilent-v4-targets-ucsc.100bp_padded.bed
├── ashion_exome_v2_targets_hg38_padded100.bed
├── biospecimen_id_to_bed_map.tsv
├── cnv-cnvkit.seg.gz
├── cnv-consensus-gistic.zip
├── cnv-consensus.seg.gz
├── cnv-controlfreec.tsv.gz
├── cnv-gatk.seg.gz
├── cnvkit_with_status.tsv
├── consensus_seg_with_status.tsv
├── consensus_wgs_plus_cnvkit_wxs.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz
├── efo-mondo-map.tsv
├── ensg-hugo-pmtl-mapping.tsv
├── fusion-annoFuse.tsv.gz
├── fusion-arriba.tsv.gz
├── fusion-dgd.tsv.gz
├── fusion-putative-oncogenic.tsv
├── fusion-starfusion.tsv.gz
├── fusion_summary_embryonal_foi.tsv
├── fusion_summary_ependymoma_foi.tsv
├── fusion_summary_ewings_foi.tsv
├── fusion_summary_lgg_hgg_foi.tsv
├── gene-counts-rsem-expected_count-collapsed.rds
├── gene-expression-rsem-tpm-collapsed.rds
├── hg38_strelka.bed
├── histologies-base.tsv
├── histologies.tsv
├── independent-specimens.methyl.primary-plus.eachcohort.tsv
├── independent-specimens.methyl.primary-plus.tsv
├── independent-specimens.methyl.primary.eachcohort.tsv
├── independent-specimens.methyl.primary.tsv
├── independent-specimens.methyl.relapse.eachcohort.tsv
├── independent-specimens.methyl.relapse.tsv
├── independent-specimens.rnaseq.primary-plus-pre-release.tsv
├── independent-specimens.rnaseq.primary-pre-release.tsv
├── independent-specimens.rnaseq.relapse-pre-release.tsv
├── independent-specimens.rnaseqpanel.primary-plus.eachcohort.tsv
├── independent-specimens.rnaseqpanel.primary-plus.tsv
├── independent-specimens.rnaseqpanel.primary.eachcohort.tsv
├── independent-specimens.rnaseqpanel.primary.tsv
├── independent-specimens.rnaseqpanel.relapse.eachcohort.tsv
├── independent-specimens.rnaseqpanel.relapse.tsv
├── independent-specimens.wgs.primary-plus.eachcohort.tsv
├── independent-specimens.wgs.primary-plus.tsv
├── independent-specimens.wgs.primary.eachcohort.tsv
├── independent-specimens.wgs.primary.tsv
├── independent-specimens.wgs.relapse.eachcohort.tsv
├── independent-specimens.wgs.relapse.tsv
├── independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.primary-plus.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.primary-plus.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.primary.eachcohort.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.primary.eachcohort.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.primary.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.primary.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.relapse.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.relapse.prefer.wxs.tsv
├── infinium-annotation-mapping.tsv
├── infinium-methylationepic-v-1-0-b5-manifest-file-csv.zip
├── intersect_cds_lancet_strelka_mutect_WGS.bed
├── intersect_strelka_mutect_WGS.bed
├── md5sum.txt
├── methyl-beta-values.rds
├── methyl-m-values.rds
├── methyl-md5sum.txt
├── nexterarapidcapture_exome_targetedregions_v1.2_hg38_100.bed
├── onco1500-v2-targets-ucsc.100bp_padded.bed
├── onco1500-v4-targets-ucsc.100bp_padded.bed
├── onco1500-v6-targets-ucsc.100bp_padded.bed
├── onco1500-v6a-targets-ucsc.100bp_padded.bed
├── release-notes.md
├── rna-isoform-expression-rsem-tpm.rds
├── snv-consensus-plus-hotspots.maf.tsv
├── snv-consensus-plus-hotspots.maf.tsv.gz
├── snv-dgd.maf.tsv.gz
├── snv-mutation-tmb-all.tsv
├── snv-mutation-tmb-coding.tsv
├── splice-events-rmats.tsv.gz
├── sv-manta.tsv.gz
├── tcga-gene-expression-rsem-tpm-collapsed.rds
├── truseq-exome-targeted-regions-manifest-v1-2_hg38_100.bed
├── uberon-map-gtex-group.tsv
├── uberon-map-gtex-subgroup.tsv
├── wgs_canonical_calling_regions.hg38.bed
└── xgen-exome-research-panel-targets_hg38_ucsc_liftover.100bp_padded.sort.merged.bed
```

### release-v11
- release date: 2022-07-07
- status: available
- overview of changes (See [PR 188](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/pull/188) for additional details):
  - This release adds the following data:
    - 11 RNA-Seq and WXS PBTA samples (plus 2 WXS PBTA results from previous release)
    - 1799 DGD tumor samples (929 DNA, 870 RNA)
    - methylation array data from
      - normal samples: 
        - 5 PBTA samples
        - 12 TARGET samples
      - tumor samples: [Ticket 278](https://github.com/PediatricOpenTargets/ticket-tracker/issues/278) and [Ticket 269](https://github.com/PediatricOpenTargets/ticket-tracker/issues/269)
        - 1146 PBTA samples
        - 751 TARGET samples
      - RNA isoform merged TPM samples
  - Update TCGA RNA-Seq data to use GENCODE v36 GDC
    - [Ticket 285](https://github.com/PediatricOpenTargets/ticket-tracker/issues/285)
    - [Ticket 308](https://github.com/PediatricOpenTargets/ticket-tracker/issues/308)
  - All additional changes as well as details about the above changes are as followed.

- Add base histologies file to data release, see [ticket 333](https://github.com/PediatricOpenTargets/ticket-tracker/issues/333)
- Update histologies file - key changes noted here (other tickets can be found in OpenPedCan repo)
    - Change cancer_group of `Metastatic secondary tumors;Neuroblastoma` to `Neuroblastoma`
            - See discussion in [ticket 232](https://github.com/PediatricOpenTargets/ticket-tracker/issues/232)
            - [Ticket 234](https://github.com/PediatricOpenTargets/ticket-tracker/issues/234)
    - Update `primary_site` for some GMKF and TARGET NBL samples to resolve lumped together `primary_site` issues
            - [Ticket 257](https://github.com/PediatricOpenTargets/ticket-tracker/issues/257)
    - Update histologies file to use `pathology_diagnosis` (when available) or `cancer_group` (when path dx not available) to fill in `harmonized_diagnosis`  for non-PBTA samples
            - [Ticket 259](https://github.com/PediatricOpenTargets/ticket-tracker/issues/259)
     - DGD histologies cleanup: [ticket 325](https://github.com/PediatricOpenTargets/ticket-tracker/issues/325)
     - Fix `short_histology` for PBTA cohort: [ticket 309](https://github.com/PediatricOpenTargets/ticket-tracker/issues/309)
     - Add extent of tumor resection: [ticket 298](https://github.com/PediatricOpenTargets/ticket-tracker/issues/298)

- Update EFO MONDO file 
    - Create `efo-mondo-map-prefill.tsv` file based on `cancer_group` generated in `molecular-subtyping-integrate`: [PR 176](https://github.com/PediatricOpenTargets/OpenPedCan-analysis/pull/176)
    - Update EFO MONDO map file to contain new cancer group in v10 histologies file: [ticket 237](https://github.com/PediatricOpenTargets/ticket-tracker/issues/237)
    - Add NCIT column to the EFO MONDO map file: [ticket 261](https://github.com/PediatricOpenTargets/ticket-tracker/issues/261)
- Update `ensg-hugo-pmtl-mapping.tsv` to remove NA line: [ticket 231](https://github.com/PediatricOpenTargets/ticket-tracker/issues/231)

- Re-run independent samples module to accommodate new cancer groups and additional samples: [ticket 370](https://github.com/PediatricOpenTargets/ticket-tracker/issues/304) and [Ticket 370](https://github.com/PediatricOpenTargets/ticket-tracker/issues/370)
- Add pre-release RNA-Seq only independent specimens 
- Add concatenated DGD MAF files to data release as `snv-dgd.maf.tsv.gz`: [ticket 248](https://github.com/PediatricOpenTargets/ticket-tracker/issues/248)
- Add concatenated DGD fusion files as `fusion-dgd.tsv.gz`: [ticket 249](https://github.com/PediatricOpenTargets/ticket-tracker/issues/249)
- Update DNA and RNA delivery data files with new PBTA samples: [ticket 253](https://github.com/PediatricOpenTargets/ticket-tracker/issues/253)
- Re-run fusion filtering: [ticket 316](https://github.com/PediatricOpenTargets/ticket-tracker/issues/316)
- Update focal CN preparation module to fine tune ENSEMBL, gene symbol, and cytoband matching
   - [Ticket 320](https://github.com/PediatricOpenTargets/ticket-tracker/issues/320)
   - [Ticket 318](https://github.com/PediatricOpenTargets/ticket-tracker/issues/318)
- Rerun `focal-cn-preparation`: [ticket 254](https://github.com/PediatricOpenTargets/ticket-tracker/issues/254)
- Run molecular subtyping for all samples
    - [Ticket 299](https://github.com/PediatricOpenTargets/ticket-tracker/issues/299)
    - [Ticket 303](https://github.com/PediatricOpenTargets/ticket-tracker/issues/303)
    - Updates:
        - Added DGD samples to medulloblastoma and craniopharyngioma subtyping
        - Modified EPN subtyping per [Ticket 365](https://github.com/PediatricOpenTargets/ticket-tracker/issues/365)
        - Add methylation bs_ids in neurocytoma subtyping

- Update the download script to change from v10 to v11 and GENCODE file: [ticket 270](https://github.com/PediatricOpenTargets/ticket-tracker/issues/270)
- Add bed files for TMB calculation and TMB results to data release 
    - [Ticket 250](https://github.com/PediatricOpenTargets/ticket-tracker/issues/250)
    - [Ticket 258](https://github.com/PediatricOpenTargets/ticket-tracker/issues/258)
- Run GISTIC module and upload zip file for data release: [Ticket 302](https://github.com/PediatricOpenTargets/ticket-tracker/issues/302)
- Merge all RNA isoform files into one for data release and downstream analyses: [Ticket 341](https://github.com/PediatricOpenTargets/ticket-tracker/issues/341)

- Add fusion summary files required for subtyping modules [Ticket 239](https://github.com/PediatricOpenTargets/ticket-tracker/issues/239):
  - `fusion_summary_embryonal_foi.tsv`
  - `fusion_summary_ependymoma_foi.tsv`
  - `fusion_summary_ewings_foi.tsv`
  - `fusion_summary_lgat_foi.tsv`

```
v11
├── ashion_exome_v2_targets_hg38_padded100.bed
├── biospecimen_id_to_bed_map.txt
├── cnv-cnvkit.seg.gz
├── cnv-controlfreec.tsv.gz
├── cnv-consensus.seg.gz
├── cnv-consensus-gistic.zip
├── cnvkit_with_status.tsv
├── consensus_seg_with_status.tsv
├── consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs.tsv.gz
├── data-files-description.md
├── efo-mondo-map.tsv
├── ensg-hugo-pmtl-mapping.tsv
├── fusion-arriba.tsv.gz
├── fusion-starfusion.tsv.gz
├── fusion-putative-oncogenic.tsv
├── gene-counts-rsem-expected_count-collapsed.rds
├── gene-expression-rsem-tpm-collapsed.rds
├── histologies.tsv
├── histologies-base.tsv
├── independent-specimens.methyl.primary-plus.tsv
├── independent-specimens.methyl.primary.tsv
├── independent-specimens.methyl.relapse.tsv
├── independent-specimens.rnaseq.primary-plus-pre-release.tsv
├── independent-specimens.rnaseq.primary-pre-release.tsv
├── independent-specimens.rnaseq.primary.eachcohort.tsv
├── independent-specimens.rnaseq.primary.tsv
├── independent-specimens.rnaseq.relapse-pre-release.tsv
├── independent-specimens.rnaseq.relapse.eachcohort.tsv
├── independent-specimens.rnaseq.relapse.tsv
├── independent-specimens.rnaseqpanel.primary-plus.eachcohort.tsv
├── independent-specimens.rnaseqpanel.primary-plus.pre-release.tsv
├── independent-specimens.rnaseqpanel.primary-plus.tsv
├── independent-specimens.rnaseqpanel.primary.eachcohort.tsv
├── independent-specimens.rnaseqpanel.primary.pre-release.tsv
├── independent-specimens.rnaseqpanel.primary.tsv
├── independent-specimens.rnaseqpanel.relapse.eachcohort.tsv
├── independent-specimens.rnaseqpanel.relapse.pre-release.tsv
├── independent-specimens.rnaseqpanel.relapse.tsv
├── independent-specimens.wgs.primary-plus.eachcohort.tsv
├── independent-specimens.wgs.primary-plus.tsv
├── independent-specimens.wgs.primary.eachcohort.tsv
├── independent-specimens.wgs.primary.tsv
├── independent-specimens.wgs.relapse.eachcohort.tsv
├── independent-specimens.wgs.relapse.tsv
├── independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.primary-plus.eachcohort.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.primary-plus.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.primary-plus.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.primary.eachcohort.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.primary.eachcohort.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.primary.eachcohort.tsv
├── independent-specimens.wgswxspanel.primary.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.primary.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.primary.tsv
├── independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.relapse.eachcohort.tsv
├── independent-specimens.wgswxspanel.relapse.prefer.wgs.tsv
├── independent-specimens.wgswxspanel.relapse.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.relapse.tsv
├── md5sum.txt
├── intersect_cds_lancet_strelka_mutect_WGS.bed
├── intersect_strelka_mutect_WGS.bed
├── nexterarapidcapture_exome_targetedregions_v1.2_hg38_100.bed
├── release-notes.md
├── rna-isoform-expression-rsem-tpm.rds
├── S0274956_Padded_HG38.merged.bed
├── S02972011_Covered_hg38_100.bed
├── S04380110_Regions_hg38_100.bed
├── S07604715_100bp_Padded.bed
├── SeqCap_EZ_Exome_v2_Padded_HG38.merged.bed
├── StrexomeLite_hg38_liftover_100bp_padded.bed
├── Strexome_targets_intersect_sorted_padded100.GRCh38.bed
├── TARGET_AML_NBL_WT_SeqVal79_attempt06_AllTracks_HG38_bed_expanded100.bed
├── tcga-gene-counts-rsem-expected_count-collapsed.rds
├── tcga-gene-expression-rsem-tpm-collapsed.rds
├── truseq-exome-targeted-regions-manifest-v1-2_hg38_100.bed
├── WGS.hg38.lancet.300bp_padded.bed
├── WGS.hg38.lancet.unpadded.bed
├── WGS.hg38.mutect2.vardict.unpadded.bed
├── WGS.hg38.strelka2.unpadded.bed
├── WGS.hg38.vardict.100bp_padded.bed
├── snv-consensus-plus-hotspots.maf.tsv.gz
├── sv-manta.tsv.gz
├── methyl-beta-values.rds
├── methyl-m-values.rds
├── snv-dgd.maf.tsv.gz
├── fusion-dgd.tsv
├── snv-mutation-tmb-all.tsv
├── snv-mutation-tmb-coding.tsv
├── uberon-map-gtex-group.tsv
├── uberon-map-gtex-subgroup.tsv
├── wgs_canonical_calling_regions.hg38.bed
└── xgen-exome-research-panel-targets_hg38_ucsc_liftover.100bp_padded.sort.merged.bed

```

## archived release
### release-v10
- release date: 2021-10-11
- status: available
- overview of changes:
  - This particular releae added 438 tumor/nomral pairs of TARGET ALL WXS samples as well as a total of 144 samples (including WGS, WXS, RNA-Seq for both tumor and normal) from PNOC clinical trials. 
  - Usable TCGA RNA-Seq data from diseaseXpress with GDC clinical information are added to (n=10414) were added to the release
  - `cnv-consensus-gistic.zip` from `run-gistic` module was added to the release 
  - `ensg-hugo-rmtl-mapping.tsv` is replaced with `ensg-hugo-pmtl-mapping.tsv` after we switch from RMTL v1.0 to PMTL v1.1
  - All additional changes as well as details about the above 3 changes are as followed.

- Update histologies file:
    - Add 120 samples from PNOC_dataset_2 (40 WXS tumor, 40 WXS normal and 40 RNA-Seq from 40 patients) and additional 24 PNOC_dataset_1 tumor WGS from 18 samples to release
       - Details see [ticket 174](https://github.com/PediatricOpenTargets/ticket-tracker/issues/174)
       - After `tp53-nf1-scores` and `run-gistic` modules were ran with the base histology file, these samples then ran through `molecular-subtyping-HGG`, `molecular-subtyping-pathology` and `molecular-subtyping-integrate` modules to get their subtype (details also captured below)
        - See [ticket 210](https://github.com/PediatricOpenTargets/ticket-tracker/issues/210) for details
    - Add 438 tumor/normal pairs of TARGET ALL WXS samples
       - Details see [ticket 158](https://github.com/PediatricOpenTargets/ticket-tracker/issues/158)
    - Change "Known" to "Unknown" in the histologies file since it was mis-coded before
       - Details see [ticket 192](https://github.com/PediatricOpenTargets/ticket-tracker/issues/192)
    - Fixed TCGA and GMKF/TARGET OS_days in histology file - see [ticket 199](https://github.com/PediatricOpenTargets/ticket-tracker/issues/199)
       - For TCGA samples, `OS_days` column is now populated this way: `days_to_death` column is preferentially used for `OS_days`; when it is `NA`,  `days_to_last_follow_up` is used as long as the value is not negative
       - For TARGET samples that are also present in GMKF cohort, `OS_days` in TARGET cohort are replaced with `OS_days` in GMKF cohort since GMKF has more up-to-date records
    - Remove TCGA samples in histology file that is not in the expression matrix or does not have clinical information from GDC portal 
       -  Details see [ticket 202](https://github.com/PediatricOpenTargets/ticket-tracker/issues/202)
    - Additional changes to TCGA histology file - `RNA-library` of `poly-A `and `sample_type` of `Tumor `(a total of 9551 samples) all have NA composition:
       - For these samples, `composition` is modified to `Solid Tissue` as long as `primary_site` is not NA or `Bone Marrow` 
    - Additionally, there are `normal` samples in TARGET cohort with `broad_histology`, `short_histology`, `tumor_descriptor` and `cancer_group` that are not `NA`
       - For those samples, these fields are changed to `NA` 

- Use PMTL v1.1 instead of RMTL v1.0 for gene annotation - `ensg-hugo-pmtl-mapping.tsv` will now be the included in the data release and `ensg-hugo-rmtl-mapping.tsv` will not longer be used.
       - Details see [ticket 206](https://github.com/PediatricOpenTargets/ticket-tracker/issues/206)
       
- Run molecular subtyping for new PNOC clinical trials samples 
    - Use the merged `snv-consensus-plus-hotspots.maf.tsv.gz`, `consensus_wgs_plus_cnvkit_wxs.tsv.gz`, `gene-expression-rsem-tpm-collapsed.rds` and base histology file to re-run TP53-NF1 module 
      - Details see [ticket 209](https://github.com/PediatricOpenTargets/ticket-tracker/issues/209)
    - Use the new `cnv-consensus.seg.gz` and run through GISTIC module
      - Details see [ticket 211](https://github.com/PediatricOpenTargets/ticket-tracker/issues/211)
    - Run molecular subtyping for new PNOC sample through HGG, pathology and integrate modules 
      - Details see [ticket 210](https://github.com/PediatricOpenTargets/ticket-tracker/issues/210)

- Update `cnv-cnvkit.seg.gz`, `cnv-controlfreec.tsv.gz`,`consensus_wgs_plus_cnvkit_wxs.tsv.gz`,  `snv-consensus-plus-hotspots.maf.tsv.gz` and `sv-manta.tsv` to include 438 tumor/normal pairs of TARGET ALL WXS samples as well as a total of 144 samples (including WGS, WXS, RNA-Seq for both tumor and normal) from PNOC clinical samples.
    - Details for merging PNOC clinical samples see [ticket 174](https://github.com/PediatricOpenTargets/ticket-tracker/issues/174)
    - Details for merging 438 tumor/normal pairs of TARGET ALL WXS samples see [ticket 194](https://github.com/PediatricOpenTargets/ticket-tracker/issues/194)
    
- Update EFO-MONDO mapped file to remove trailing white space that is causing error
    - Details for merging 438 tumor/nomral pairs of TARGET ALL WXS samples see [ticket 208](https://github.com/PediatricOpenTargets/ticket-tracker/issues/208)
    
- Update `gene-counts-rsem-expected_count-collapsed.rds`, `gene-expression-rsem-tpm-collapsed.rds`, `fusion-arriba.tsv.gz` and `fusion-starfusion.tsv.gz` with 40 RNA-Seq tumor sample from PNOC_dataset_2 results merged 
    - Details see [ticket 203](https://github.com/PediatricOpenTargets/ticket-tracker/issues/203) 
- Two TCGA gene expression files, `tcga-gene-counts-rsem-expected_count-collapsed.rds` and `tcga-gene-expression-rsem-tpm-collapsed.rds`, for all TCGA in diseaseXpress and has GDC clinical information (n=10414) were now include in data release 
    - Details see [ticket 200](https://github.com/PediatricOpenTargets/ticket-tracker/issues/200) 

- Update `consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz`, `consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz` and  `consensus_wgs_plus_cnvkit_wxs.tsv.gz` files with the following changes:
    - When annotating CNV status, for WXS samples, if WGS was performed on the same sample, we use the `germline_sex_estimate` from the WGS as the `germline_sex_estimate` for the WXS samples. Details see [ticket 177](https://github.com/PediatricOpenTargets/ticket-tracker/issues/177) 
    - When matching WGS samples were not available, `gender` is used as `germline_sex_estimate. Details see [ticket 177](https://github.com/PediatricOpenTargets/ticket-tracker/issues/177)  
    - Additionally, `focal-cn-file-preparation` module was re-run to include 438 tumor/normal pairs of TARGET ALL WXS samples as well as a total of 144 samples (including WGS, WXS, RNA-Seq for both tumor and normal) from PNOC clinical samples. Details see [ticket 196](https://github.com/PediatricOpenTargets/ticket-tracker/issues/196)  

- `cnv-consensus-gistic.zip` will now be added to data release after 24 WGS PNOC tumor samples were merged and the module re-run
    - Details see [ticket 218](https://github.com/PediatricOpenTargets/ticket-tracker/issues/218) 

- Independent sample lists were re-generated with the following changes:
    - In addition to what are currently in data release, we added scripts to preferentially select WXS tumor when available and the following files will now be added to data release for use by `snv-frequencies` module - Details see [ticket 193](https://github.com/PediatricOpenTargets/ticket-tracker/issues/193) 
      - `independent-specimens.wgswxspanel.primary.eachcohort.prefer.wxs.tsv`
      - `independent-specimens.wgswxspanel.primary.prefer.wxs.tsv`
      - `independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wxs.tsv`
      - `independent-specimens.wgswxspanel.relapse.prefer.wxs.tsv`
    - The independent lists are re-generated with 438 tumor/normal pairs of TARGET ALL WXS samples as well as a total of 144 samples (including WGS, WXS, RNA-Seq for both tumor and normal) from PNOC clinical samples added to the histology file
      - Details see [ticket 215](https://github.com/PediatricOpenTargets/ticket-tracker/issues/215)  

- Regenerate `fusion-putative-oncogenic.tsv` to include results from 40 RNA-Seq tumor samples from PNOC clinical trials
      - Details see [ticket 214](https://github.com/PediatricOpenTargets/ticket-tracker/issues/214)  

```
v10
├── WGS.hg38.lancet.300bp_padded.bed
├── WGS.hg38.lancet.unpadded.bed
├── WGS.hg38.mutect2.vardict.unpadded.bed
├── WGS.hg38.strelka2.unpadded.bed
├── WGS.hg38.vardict.100bp_padded.bed
├── cnv-cnvkit.seg.gz
├── cnv-controlfreec.tsv.gz
├── cnv-consensus.seg.gz
├── cnv-consensus-gistic.zip
├── consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs.tsv.gz
├── data-files-description.md
├── efo-mondo-map.tsv
├── ensg-hugo-pmtl-mapping.tsv
├── fusion-arriba.tsv.gz
├── fusion-starfusion.tsv.gz
├── fusion-putative-oncogenic.tsv
├── gene-counts-rsem-expected_count-collapsed.rds
├── gene-expression-rsem-tpm-collapsed.rds
├── tcga-gene-counts-rsem-expected_count-collapsed.rds
├── tcga-gene-expression-rsem-tpm-collapsed.rds
├── histologies.tsv
├── independent-specimens.wgswxspanel.primary.eachcohort.tsv
├── independent-specimens.wgswxspanel.relapse.eachcohort.tsv
├── independent-specimens.rnaseq.primary.eachcohort.tsv
├── independent-specimens.rnaseq.relapse.eachcohort.tsv
├── independent-specimens.wgswxspanel.primary.tsv
├── independent-specimens.wgswxspanel.relapse.tsv
├── independent-specimens.rnaseq.primary.tsv
├── independent-specimens.rnaseq.relapse.tsv
├── independent-specimens.wgswxspanel.primary.eachcohort.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.primary.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.relapse.eachcohort.prefer.wxs.tsv
├── independent-specimens.wgswxspanel.relapse.prefer.wxs.tsv
├── intersect_cds_lancet_strelka_mutect_WGS.bed
├── intersect_strelka_mutect_WGS.bed
├── release-notes.md
├── snv-consensus-plus-hotspots.maf.tsv.gz
├── sv-manta.tsv.gz
├── uberon-map-gtex-group.tsv
└── uberon-map-gtex-subgroup.tsv

```

### release-v9
- release date: 2021-09-01
- status: available
- overview of changes:
  - This particular release is just an update of `efo-mondo-map.tsv` per discussion in [ticket 182](https://github.com/PediatricOpenTargets/ticket-tracker/issues/182).
  - MONDO and EFO codes were manually reviewed and assigned to `cancer_group` in OpenPedCan.  

```
v9
├── WGS.hg38.lancet.300bp_padded.bed
├── WGS.hg38.lancet.unpadded.bed
├── WGS.hg38.mutect2.vardict.unpadded.bed
├── WGS.hg38.strelka2.unpadded.bed
├── WGS.hg38.vardict.100bp_padded.bed
├── cnv-cnvkit.seg.gz
├── cnv-controlfreec.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs.tsv.gz
├── data-files-description.md
├── efo-mondo-map.tsv
├── ensg-hugo-rmtl-mapping.tsv
├── fusion-arriba.tsv.gz
├── fusion-starfusion.tsv.gz
├── fusion-putative-oncogenic.tsv
├── gene-counts-rsem-expected_count-collapsed.rds
├── gene-expression-rsem-tpm-collapsed.rds
├── histologies.tsv
├── independent-specimens.wgswxspanel.primary.eachcohort.tsv
├── independent-specimens.wgswxspanel.relapse.eachcohort.tsv
├── independent-specimens.rnaseq.primary.eachcohort.tsv
├── independent-specimens.rnaseq.relapse.eachcohort.tsv
├── independent-specimens.wgswxspanel.primary.tsv
├── independent-specimens.wgswxspanel.relapse.tsv
├── independent-specimens.rnaseq.primary.tsv
├── independent-specimens.rnaseq.relapse.tsv
├── intersect_cds_lancet_strelka_mutect_WGS.bed
├── intersect_strelka_mutect_WGS.bed
├── release-notes.md
├── snv-consensus-plus-hotspots.maf.tsv.gz
├── sv-manta.tsv.gz
├── uberon-map-gtex-group.tsv
└── uberon-map-gtex-subgroup.tsv

```
## archived release
### release-v8
- release date: 2021-08-20
- status: available
- overview of changes:
    - This particular release is mainly to include 412 tumor/normal pairs of TARGET WXS samples as listed in [ticket 111](https://github.com/PediatricOpenTargets/ticket-tracker/issues/111). Detailed changes see below. 
- detailed changes: 
    - Histology file updates - the master ticket is d3b center [ticket 43](https://github.com/d3b-center/D3b-codes/pull/43):
      - 412 tumor/normal TARGET WXS samples were included in the histologies.tsv file per [ticket 111](https://github.com/PediatricOpenTargets/ticket-tracker/issues/111)v
      - `sample_id` and `aliquot_id` for some TARGET samples were miscoded before. This release fixed the issue per [ticket 145](https://github.com/PediatricOpenTargets/ticket-tracker/issues/145)
      - `sample_id` and `aliquot_id` were updated using the GTEx coding nomenclature GTEX-[donor ID]-[tissue site ID]-SM-[aliquot ID] (https://www.gtexportal.org/home/faq#sampleIdFormat)
      - `primary_site` for GTEx samples were updated to match `gtex_subgroup` column, changing `Whole Blood` to `Blood` and `Brain - Cerebellar Hemisphere` to `Brain - Cerebellum`
      - `broad_histology` for TARGET samples were updated as following: `Acute Lymphoblastic Leukemia` and `Acute Myeloid Leukemia` were merged to `Hematologic malignancy`; `Clear cell sarcoma of the kidney`, `Rhabdoid tumor`, and `Wilms tumor` were combined as `Renal tumor`; `Osteosarcoma` is changed to `Mesenchymal non-meningothelial tumor` and `Neuroblastoma` is converted to `Embryonal tumor`. See [ticket 136](https://github.com/PediatricOpenTargets/ticket-tracker/issues/136) and [ticket 176] (https://github.com/PediatricOpenTargets/ticket-tracker/issues/176)
      - For `gtex_group == "Cells"`, the `composition` column is changed from `Solid Tissue` to `Derived Cell Line` per discussion in d3b center [ticket 43](https://github.com/d3b-center/D3b-codes/pull/43)
      - For `short_histology`,  neuroblastoma samples previously annotated as `NBL` or `Embryonal tumor` are converted to `Neuroblastoma` to be consistent with other samples 
      - Updated MB subtypes in the histologies file per [ticket 148](https://github.com/PediatricOpenTargets/ticket-tracker/issues/148)
      - Some GMKF WGS samples does not have `germline_sex_estimate` as indicated in [ticket 168](https://github.com/PediatricOpenTargets/ticket-tracker/issues/168). Added using the file in the discussion of [ticket 159](https://github.com/PediatricOpenTargets/ticket-tracker/issues/159)
      - Some TARGET WXS samples miss `tumor_ploidy` that are actually available - and those samples now have updated ploidy using the file in the discussion session of [ticket 160](https://github.com/PediatricOpenTargets/ticket-tracker/issues/160)
    
    - Update DNA related files to include TARGET WXS DNA (412 tumor/normal pairs):
      - cnv-cnvkit.seg.gz [ticket 156](https://github.com/PediatricOpenTargets/ticket-tracker/issues/156)
      - cnv-controlfreec.tsv.gz [ticket 156](https://github.com/PediatricOpenTargets/ticket-tracker/issues/156)
      - snv-consensus-plus-hotspots.maf.tsv.gz [ticket 156](https://github.com/PediatricOpenTargets/ticket-tracker/issues/156)
    - Update method to call CNV consensus (WGS) as described in [ticket 134](https://github.com/PediatricOpenTargets/ticket-tracker/issues/134) and [ticket 149](https://github.com/PediatricOpenTargets/ticket-tracker/issues/149). Briefly, CNV called by `MantaSV` were filtered to contain only `filter == "PASS"` before going into the consensus calling workflow. In the subsequent step, instead of only retaining CNV calls that have 50% reciprocal overlap between callers (which was too stringent), the criteria is expanded to include small CNV regions that are 90% covered by a larger CNV. The consensus is the overlapping region. 
      - cnv_consensus_seg.gz (WGS samples only - in S3 bucket s3://kf-openaccess-us-east-1-prd-pbta/open-targets/v8/ but not in md5sum.txt file)
    - As a result of changing consensus calling criteria and adding new TARGET WXS DNA sample results to `cnv-cnvkit.seg.gz` and `cnv-controlfreec.tsv.gz`, the following files were updated:
      - consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz [ticket 159](https://github.com/PediatricOpenTargets/ticket-tracker/issues/159) and [ticket 160](https://github.com/PediatricOpenTargets/ticket-tracker/issues/160) (only in S3 bucket s3://kf-openaccess-us-east-1-prd-pbta/open-targets/v8/- not included in automatic download)
      - consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz [ticket 159](https://github.com/PediatricOpenTargets/ticket-tracker/issues/159) and [ticket 160](https://github.com/PediatricOpenTargets/ticket-tracker/issues/160) (only in S3 bucket s3://kf-openaccess-us-east-1-prd-pbta/open-targets/v8/- not included in automatic download)
      
    - Added `consensus_wgs_plus_cnvkit_wxs.tsv.gz` which is a merge of `consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz` and `consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz` per [ticket 161](https://github.com/PediatricOpenTargets/ticket-tracker/issues/161)
    - Updated `ensg-hugo-rmtl-mapping.tsv` file per [ticket 146](https://github.com/PediatricOpenTargets/ticket-tracker/issues/146). The previous release of this file does not contain all gene ENSG IDs and symbols that are present in `snv-consensus-plus-hotspots.maf.tsv.gz`. This update merged GENCODE V28 and V38 to allow inclusion of more gene ENSG IDs and symbols. 
    - Futher update `ensg-hugo-rmtl-mapping.tsv` [PR 48 D3b codes](https://github.com/d3b-center/D3b-codes/pull/48) to include all gene ENSG ID to symbol mappings in v7 `ensg-hugo-rmtl-mapping.tsv`.

    - Update independent samples files to include TARGET WXS DNA (412 tumor/normal pairs) - [ticket 165](https://github.com/PediatricOpenTargets/ticket-tracker/issues/165). Previously, these files were not added to our releases. Starting this release, we will also add independent sample list to our release as well. 
    - Updated independent samples so that the `Kids_First_Biospecimen_ID` for `allcohorts` and `eachcohort` match if possible: [ticket 135](https://github.com/PediatricOpenTargets/ticket-tracker/issues/135)
    - Updated independent sample module to arrange by `Kids_First_Biospecimen_ID` before writing out the file: [ticket 179](https://github.com/PediatricOpenTargets/ticket-tracker/issues/179)
    - For now, we will add files that are used by analyses modules in this file and these are the following: 
      - independent-specimens.wgswxspanel.primary.eachcohort.tsv
      - independent-specimens.wgswxspanel.relapse.eachcohort.tsv
      - independent-specimens.rnaseq.primary.eachcohort.tsv
      - independent-specimens.rnaseq.relapse.eachcohort.tsv
      - independent-specimens.wgswxspanel.primary.tsv
      - independent-specimens.wgswxspanel.relapse.tsv
      - independent-specimens.rnaseq.primary.tsv
      - independent-specimens.rnaseq.relapse.tsv
    - Updated `fusion-putative-oncogenic.tsv` since at the last step of putative oncogenic fusion filtering, we filter out fusions seen in > 4 broad_histology since they are likely artifacts and with the update of broad_histology, the result will be updated [ticket 175](https://github.com/PediatricOpenTargets/ticket-tracker/issues/175)
      - fusion-putative-oncogenic.tsv

```
v8
├── WGS.hg38.lancet.300bp_padded.bed
├── WGS.hg38.lancet.unpadded.bed
├── WGS.hg38.mutect2.vardict.unpadded.bed
├── WGS.hg38.strelka2.unpadded.bed
├── WGS.hg38.vardict.100bp_padded.bed
├── cnv-cnvkit.seg.gz
├── cnv-controlfreec.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz
├── consensus_wgs_plus_cnvkit_wxs.tsv.gz
├── data-files-description.md
├── efo-mondo-map.tsv
├── ensg-hugo-rmtl-mapping.tsv
├── fusion-arriba.tsv.gz
├── fusion-starfusion.tsv.gz
├── fusion-putative-oncogenic.tsv
├── gene-counts-rsem-expected_count-collapsed.rds
├── gene-expression-rsem-tpm-collapsed.rds
├── histologies.tsv
├── independent-specimens.wgswxspanel.primary.eachcohort.tsv
├── independent-specimens.wgswxspanel.relapse.eachcohort.tsv
├── independent-specimens.rnaseq.primary.eachcohort.tsv
├── independent-specimens.rnaseq.relapse.eachcohort.tsv
├── independent-specimens.wgswxspanel.primary.tsv
├── independent-specimens.wgswxspanel.relapse.tsv
├── independent-specimens.rnaseq.primary.tsv
├── independent-specimens.rnaseq.relapse.tsv
├── intersect_cds_lancet_strelka_mutect_WGS.bed
├── intersect_strelka_mutect_WGS.bed
├── release-notes.md
├── snv-consensus-plus-hotspots.maf.tsv.gz
├── sv-manta.tsv.gz
├── uberon-map-gtex-group.tsv
└── uberon-map-gtex-subgroup.tsv

```

## archived release
### release-v7
- release date: 2021-07-23
- status: available
- changes:
   - Updated EFO/MONDO mapping file per [ticket 88](https://github.com/PediatricOpenTargets/ticket-tracker/issues/88)
   - Added GTEX UBERON mapping files for subgroup and group per [ticket 85](https://github.com/PediatricOpenTargets/ticket-tracker/issues/85)
     - Collapsed `Cerebellum hemisphere` and `Cerebellum` to `Cerebellum` since GTEX has the same UBERON code listed for both per [ticket 106](https://github.com/PediatricOpenTargets/ticket-tracker/issues/106)
     - Renamed `Whole Blood` to `Blood` per John Maris's suggestion to alphabetize and [ticket 106](https://github.com/PediatricOpenTargets/ticket-tracker/issues/106). 
       - Note: v8 gtex lists "whole blood" subgroup and "whole blood" group as UBERON_0013756, which is mapped to venous blood and "Whole blood" maps to UBERON_0000178. 
       - After inquiry at GTEx, we were told they are equivalent terms as seen in [this link](https://www.ebi.ac.uk/ols/ontologies/uberon/terms?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FUBERON_0013756)
    - Updated `ensg-hugo-rmtl-v1-mapping.tsv` with minor updates according to [ticket 125](https://github.com/PediatricOpenTargets/ticket-tracker/issues/125) and changed filename to `ensg-hugo-rmtl-mapping.tsv`
    - Histology file updates:
      - Collapsed `Cerebellum hemisphere` and `Cerebellum` to `Cerebellum` since GTEX has the same UBERON code listed for both per [ticket 106](https://github.com/PediatricOpenTargets/ticket-tracker/issues/106)
      - Renamed `Whole Blood` to `Blood` per John Maris's suggestion to alphabetize and [ticket 106](https://github.com/PediatricOpenTargets/ticket-tracker/issues/106). 
      - Added inferred strandedness to RNA-Seq samples per [ticket 104](https://github.com/PediatricOpenTargets/ticket-tracker/issues/104)
      - Added `broad_tumor_descriptor` to designate grouped `Diagnosis` and `Relapse` samples used in SNV, CNV, Fusion tables as well as for grouping on pedcbio per [ticket 109](https://github.com/PediatricOpenTargets/ticket-tracker/issues/109)
      - Added ploidy information for TARGET AML and NBL WXS samples per [ticket 121](https://github.com/PediatricOpenTargets/ticket-tracker/issues/121)
      - Collapsed TARGET ids containing suffixes to match the BAM file sample IDs from GDC and match the RDS processed files per [comment here](https://github.com/d3b-center/D3b-codes/pull/41#issuecomment-885809293)
    - Added TARGET NBL and AML WXS, PBTA WXS CNV calls to `cnv-cnvkit.seg.gz` and `cnv-controlfreec.tsv.gz` per [ticket 80](https://github.com/PediatricOpenTargets/ticket-tracker/issues/80) 
    - Added `consensus_wgs_plus_cnvkit_wxs_x_and_y.tsv.gz` (removed WGS only file `consensus_seg_annotated_cn_autosomes.tsv.gz`) and `consensus_wgs_plus_cnvkit_wxs_autosomes.tsv.gz` (removed WGS only file `consensus_seg_annotated_cn_x_and_y.tsv.gz`) containing consensus WGS and CNVkit WXS data per [ticket 102](https://github.com/PediatricOpenTargets/ticket-tracker/issues/102)
    - Updated RNA-Seq files to include TARGET RNA (N = 1329) samples:
      - fusion-arriba.tsv.gz
      - fusion-starfusion.tsv.gz
      - fusion-putative-oncogenic.tsv
      - gene-counts-rsem-expected_count-collapsed.rds
      - gene-expression-rsem-tpm-collapsed.rds

## archived release
### release-v6
- release date: 2021-06-29
- status: available
- changes:
   - Within `histologies.tsv`:
     - Updated `cancer_group` logic to make updates as per [ticket48](https://github.com/PediatricOpenTargets/ticket-tracker/issues/48)
     - combine CBTN+PNOC into `cohort == PBTA` [ticket79](https://github.com/PediatricOpenTargets/ticket-tracker/issues/79)
     - GMKF tumor ploidy was added [ticket46](https://github.com/PediatricOpenTargets/ticket-tracker/issues/46)
     - harmonized tumor_descriptor per [ticket61](https://github.com/PediatricOpenTargets/ticket-tracker/issues/61) 
     - updated clinical info for NBL samples which were missing in source files per [ticket43](https://github.com/PediatricOpenTargets/ticket-tracker/issues/43)
     - updated `experimental_strategy` for targeted capture samples per [ticket62](https://github.com/PediatricOpenTargets/ticket-tracker/issues/62)
   - Add cnv files with PBTA+GMKF samples per [ticket44](https://github.com/PediatricOpenTargets/ticket-tracker/issues/44):
      - cnv-cnvkit.seg.gz
      - cnv-controlfreec.tsv.gz
      - cnv-consensus.seg.gz 
      - consensus_seg_annotated_cn_autosomes.tsv.gz
      - consensus_seg_annotated_cn_autosomes_xy.tsv.gz
    - Add EFO and MONDO cancer mapping file [ticket78](https://github.com/PediatricOpenTargets/ticket-tracker/issues/78):
    - Add ENSG to HUGO mapping file with RMTL designation [ticket84](https://github.com/PediatricOpenTargets/ticket-tracker/issues/84) and [ticket56](https://github.com/PediatricOpenTargets/ticket-tracker/issues/56)


## archived release
### release-v5
- release date: 2021-06-17
- status: available
- changes:
  - Removed
     - gtex_target_tcga-gene-expression-rsem-tpm-collapsed.polya.rds
     - gtex_target_tcga-gene-counts-rsem-expected_count-collapsed.rds 
  - Update RSEM files to include GTEXv8 files
     - gene-expression-rsem-tpm-collapsed.rds
     - gene-counts-rsem-expected_count-collapsed.rds
  - Update manifest to include GTEx manifest are now v8, TCGA manifest are from GDC and TARGET manifest from Diskin Lab and @afarrel
     - histologies.tsv
  - Added snv PBTA+GMKF maf file
     - snv-consensus-plus-hotspots.maf.tsv.gz 
  - Released files below

```
v5
├── WGS.hg38.lancet.300bp_padded.bed
├── WGS.hg38.lancet.unpadded.bed
├── WGS.hg38.mutect2.vardict.unpadded.bed
├── WGS.hg38.strelka2.unpadded.bed
├── WGS.hg38.vardict.100bp_padded.bed
├── fusion-arriba.tsv.gz
├── fusion-starfusion.tsv.gz
├── gene-counts-rsem-expected_count-collapsed.rds
├── gene-counts-rsem-expected_count.rds
├── gene-expression-rsem-tpm-collapsed.rds
├── gene-expression-rsem-tpm.rds
├── histologies.tsv
├── intersect_cds_lancet_strelka_mutect_WGS.bed
├── intersect_strelka_mutect_WGS.bed
├── snv-consensus-plus-hotspots.maf.tsv.gz
└── release-notes.md

```

## archived release
### release-v4
- release date: 2021-06-01
- status: available
- changes:
  - Update rnseq file names to be generic (currently includes PBTA and KFNBL)
    - `gene-counts-rsem-expected_count*`
    - `gene-expression-rsem-tpm*`
    - `fusion*`
  - Added mereged gtex_target_tcga expected_count file
    - `gtex_target_tcga-gene-counts-rsem-expected_count-collapsed.rds`
  - Combined PBTA, KFNBL, TARGET, TCGA, GTEX histologies into `histologies.tsv`  
  - Released files below

```
v4
├── WGS.hg38.lancet.300bp_padded.bed
├── WGS.hg38.lancet.unpadded.bed
├── WGS.hg38.mutect2.vardict.unpadded.bed
├── WGS.hg38.strelka2.unpadded.bed
├── WGS.hg38.vardict.100bp_padded.bed
├── fusion-arriba.tsv.gz
├── fusion-starfusion.tsv.gz
├── gene-counts-rsem-expected_count-collapsed.rds
├── gene-counts-rsem-expected_count.rds
├── gene-expression-rsem-tpm-collapsed.rds
├── gene-expression-rsem-tpm.rds
├── gtex_target_tcga-gene-counts-rsem-expected_count-collapsed.rds
├── histologies.tsv
├── intersect_cds_lancet_strelka_mutect_WGS.bed
├── intersect_strelka_mutect_WGS.bed
├── kfnbl-snv-lancet.vep.maf.gz
├── kfnbl-snv-mutect2.vep.maf.gz
├── kfnbl-snv-strelka2.vep.maf.gz
├── kfnbl-snv-vardict.vep.maf.gz
└── release-notes.md

```

## archived release
### release-v3
- release date: 2021-05-21
- status: available
- changes:
  - Update files due to addition of `SSF` column name 
    -  kfnbl-snv-vardict.vep.maf.gz
  - Added files for downstream analysis output files from `collapse-rnaseq`
    -  kfnbl-gene-counts-rsem-expected_count-collapsed.stranded.rds   
  - Released files below:

```
v3
├── WGS.hg38.lancet.300bp_padded.bed
├── WGS.hg38.lancet.unpadded.bed
├── WGS.hg38.mutect2.vardict.unpadded.bed
├── WGS.hg38.strelka2.unpadded.bed
├── WGS.hg38.vardict.100bp_padded.bed
├── gtex-gene-expression-rsem-tpm-collapsed.polya.rds
├── gtex-histologies.tsv
├── intersect_cds_lancet_strelka_mutect_WGS.bed
├── intersect_strelka_mutect_WGS.bed
├── kfnbl-fusion-arriba.tsv.gz
├── kfnbl-fusion-starfusion.tsv.gz
├── kfnbl-gene-counts-rsem-expected_count-collapsed.stranded.rds
├── kfnbl-gene-counts-rsem-expected_count.stranded.rds
├── kfnbl-gene-expression-kallisto.stranded.rds
├── kfnbl-gene-expression-rsem-fpkm-collapsed.stranded.rds
├── kfnbl-gene-expression-rsem-fpkm.stranded.rds
├── kfnbl-gene-expression-rsem-tpm-collapsed.stranded.rds
├── kfnbl-gene-expression-rsem-tpm.stranded.rds
├── kfnbl-histologies.tsv
├── kfnbl-isoform-counts-rsem-expected_count.stranded.rds
├── kfnbl-isoform-expression-rsem-tpm.stranded.rds
├── kfnbl-snv-lancet.vep.maf.gz
├── kfnbl-snv-mutect2.vep.maf.gz
├── kfnbl-snv-strelka2.vep.maf.gz
├── kfnbl-snv-vardict.vep.maf.gz
├── release-notes.md
├── target-gene-expression-rsem-tpm-collapsed.rds
├── target-histologies.tsv
├── tcga-gene-expression-rsem-tpm-collapsed.rds
└── tcga-histologies.tsv
```

## archived release
### release-v2
- release date: 2021-05-18
- status: available
- changes:
  - Updated rnaseq files with addition of BS_ETC8R0TD 
    - kfnbl-fusion-arriba.tsv.gz
    - kfnbl-fusion-starfusion.tsv.gz
    - kfnbl-gene-counts-rsem-expected_count.stranded.rds
    - kfnbl-gene-expression-kallisto.stranded.rds
    - kfnbl-gene-expression-rsem-fpkm.stranded.rds
    - kfnbl-gene-expression-rsem-fpkm-collapsed.stranded.rds
    - kfnbl-gene-expression-rsem-tpm.stranded.rds
    - kfnbl-gene-expression-rsem-tpm-collapsed.stranded.rds
    - kfnbl-isoform-counts-rsem-expected_count.stranded.rds
    - kfnbl-isoform-expression-rsem-tpm.stranded.rds
    - kfnbl-histologies.tsv 
  - Released files below: 
```
open-targets
└── v2
    ├── gtex-gene-expression-rsem-tpm-collapsed.polya.rds
    ├── gtex-histologies.tsv
    ├── intersect_cds_lancet_strelka_mutect_WGS.bed
    ├── intersect_strelka_mutect_WGS.bed
    ├── md5sum.txt
    ├── kfnbl-fusion-arriba.tsv.gz
    ├── kfnbl-fusion-starfusion.tsv.gz
    ├── kfnbl-gene-counts-rsem-expected_count.stranded.rds
    ├── kfnbl-gene-expression-kallisto.stranded.rds
    ├── kfnbl-gene-expression-rsem-fpkm.stranded.rds
    ├── kfnbl-gene-expression-rsem-fpkm-collapsed.stranded.rds
    ├── kfnbl-gene-expression-rsem-tpm.stranded.rds
    ├── kfnbl-gene-expression-rsem-tpm-collapsed.stranded.rds
    ├── kfnbl-isoform-counts-rsem-expected_count.stranded.rds
    ├── kfnbl-isoform-expression-rsem-tpm.stranded.rds
    ├── kfnbl-histologies.tsv    
    ├── kfnbl-snv-lancet.vep.maf.gz
    ├── kfnbl-snv-mutect2.vep.maf.gz
    ├── kfnbl-snv-strelka2.vep.maf.gz
    ├── kfnbl-snv-vardict.vep.maf.gz
    ├── release-notes.md 
    ├── target-gene-expression-rsem-tpm-collapsed.rds
    ├── target-histologies.tsv
    ├── tcga-gene-expression-rsem-tpm-collapsed.rds
    ├── tcga-histologies.tsv
    ├── WGS.hg38.lancet.300bp_padded.bed
    ├── WGS.hg38.lancet.unpadded.bed
    ├── WGS.hg38.mutect2.vardict.unpadded.bed
    ├── WGS.hg38.strelka2.unpadded.bed
    └── WGS.hg38.vardict.100bp_padded.bed
```

## archived release
### release-v1
- release date: 2021-04-21
- status: available
- changes:
  - Added files below: 
```
open-targets
└── v1
    ├── intersect_cds_lancet_strelka_mutect_WGS.bed
    ├── intersect_strelka_mutect_WGS.bed
    ├── md5sum.txt
    ├── kfnbl-gene-counts-rsem-expected_count.stranded.rds
    ├── kfnbl-gene-expression-rsem-fpkm.stranded.rds
    ├── kfnbl-gene-expression-rsem-tpm.stranded.rds
    ├── kfnbl-histologies.tsv    
    ├── kfnbl-snv-lancet.vep.maf.gz
    ├── kfnbl-snv-mutect2.vep.maf.gz
    ├── kfnbl-snv-strelka2.vep.maf.gz
    ├── kfnbl-snv-vardict.vep.maf.gz
    ├── release-notes.md
    ├── WGS.hg38.lancet.300bp_padded.bed
    ├── WGS.hg38.lancet.unpadded.bed
    ├── WGS.hg38.mutect2.vardict.unpadded.bed
    ├── WGS.hg38.strelka2.unpadded.bed
    └── WGS.hg38.vardict.100bp_padded.bed
```
