# Molecular Subtyping NBL
**Module authors**: Aditya Lahiri ([@adilahiri](https://github.com/adilahiri)), Eric Wafula ([@ewafula](https://github.com/ewafula)), and Jo Lynne Rokita ([@jharenza](https://github.com/jharenza))


Objective: To molecularly subtype neuroblastoma, ganglioneuroblastoma, and ganglioneuroma samples into MYCN 
amplified or MYCN non-amplified ([Ticket#417](https://github.com/PediatricOpenTargets/ticket-tracker/issues/417)).
MYCN is located on chromosone 2p and the subtyping is done by checking the CNV calls and the
clinically-reported MYCN status. We also perform QC by checking the consistency between TARGET and GMKF NBL samples.

**Subtyping criteria**:

**case 1**:
If `pathology_free_text_diagnosis` is **amplified** and `status` is **amplified** assign subtype as `NBL, MYCN amplified`

**case 2**:
If `pathology_free_text_diagnosis` is **non-amp** and `status` is **amplified** assign subtype as `NBL, MYCN amplified`

**case 3**:
If `pathology_free_text_diagnosis` is **non-amp** and `status` is **non-amp** assign subtype as `NBL, MYCN non-amplified`

**case 4**:
If `pathology_free_text_diagnosis` is **amplified** and status is **non-amp**
For such samples if there exists a TPM value, evaluate if the TPM is above or below 140.83 (`Suggested_Cutoff`) established in the image `plots/tpm_biospecimen_all_samples_with_tpm.png` assign subtype as `NBL, MYCN amplified` or `NBL, MYCN non-amplified` respectively.  In case there is no TPM values then assign the subtype as `NBL, to be classified`. 

**case 5**:
If there are samples that are not yet subtyped but have a TPM value, assign them a subtype by assessing if they are above or below
the TPM value of 140.83 (`Suggested_Cutoff`).  

**case 6**:
Other remaining samples are not subtyped and the subtype field is left as `NBL, to be classified`.

**Note**: The files in the input folder are NBL MCYN `clinical patient-status mapping files` for GMKF and TARGET samples. In V11 some values of the `pathology_free_text_diagnosis` are missing, these input files fill in some of these missing values. 

# Usage
To run the module, execute the following command from the command line in the directory `OpenPedCan-analysis/analyses/molecular-subtyping-NBL` 

`bash run-molecular-subtyping-NBL.sh `

# Module Content
1. `run-molecular-subtyping-NBL.sh`: Bash script to execute this module. 

2. `input/gmkf_patient_clinical_mycn_status.tsv`: Has values for `pathology_free_text_diagnosis` in the GMKF cohort. These values are not present in the V11 data and will be made available in V12.

3. `input/target_patient_clinical_mycn_status.tsv`: Has values for `pathology_free_text_diagnosis` in the TARGET cohort. These values are not present in the V11 data and will be made available in V12.

4. `00-subset-for-NBL.Rmd`: This scripts filters the files `histologies-base.tsv` for neuroblastama, ganglioneuroblastoma, and ganglioneuroma which need to be subptyped. Furthermore, it integrates consensus and TPM information from the files `consensus_wgs_plus_cnvkit_wxs.tsv.gz` and `gene-expression-rsem-tpm-collapsed.rds`. The data obtained after preprocessing these 
files can be segregated as matched and unmatched samples. The biospecimensamples whose DNA and RNA IDs are matched through a matching process are called matched samples, and those samples which don't have matched DNA and RNA IDs are called unmatched samples. These samples are stored in the table `input/mycn_nbl_subset_data.tsv`. 

5. `01-find-matched-biospecimen.Rmd`: This script loads the file `input/mycn_nbl_subset_data.tsv` and 
identifies biospecimen samples which have matched DNA and RNA IDs, and plots their TPM values. The plot can be found in `plots/tpm_biospecimen_matching.png`. The matched samples are stored in the file `input/mycn_nbl_matched_biospecimen.tsv`,
the DNA only samples are stores in `input/mycn_nbl_dna_biospecimen.tsv` and RNA only samples are stored in `mycn_nbl_rna_biospecimen.tsv`.

6. `02-find-non-matching-biospecimen.Rmd`: This script identifies biospecimen samples which do not have matched DNA and RNA IDs,
and plots their TPM values. The plot can be found in `plots/tpm_biospecimen_matching.png`. The input to this script consist of `gmkf_patient_clinical_mycn_status.tsv`,`target_patient_clinical_mycn_status.tsv` and three files generated in script `01-find-matched-biospecimen.Rmd`. This script generates the table `input/alteration_table_without_molecular_subtype.tsv` which contain 
the samples that need to be subtyped.

7. `03-subtyping.Rmd`: This script performs the subtyping of the samples as mentioned in cases 1-6 and stores the results in
 `results/neuroblastoma_molecular_subtypes.tsv`. This script also generates the table, `results/molecular_subtypes_based_on_cutoff.tsv` and `results/alteration_table_with_molecular_subtype.tsv`. `results/molecular_subtypes_based_on_cutoff.tsv` exclusively lists all the biospecimens whose TPM values were used in determing
 their subtypes. `results/alteration_table_with_molecular_subtype.tsv` is a detailed version of the primary result table `results/neuroblastoma_molecular_subtypes.tsv` (please read description below). The input to this script are `input/alteration_table_without_molecular_subtype.tsv`, `cnv-cnvkit.seg.gz`, and `histologies-base.tsv`.

8. `04-qc-checks.Rmd`: Checks for consistency between TARGET and GMKF NBL sample. Results are stored in `results/qc_table.tsv`.


9. `results/neuroblastoma_molecular_subtypes.tsv`: This table is the primary output file for this module. For each biospecimen sample, the table  lists its DNA and RNA IDs (if available) and their subtype. 

10. `results/alteration_table_with_molecular_subtype.tsv`: This table is a more detailed version of the table `results/neuroblastoma_molecular_subtypes.tsv`. This table has additional columns which contain information on `MYCN_TPM`,	`copy_number`,	`status`, and	`pathology_free_text_diagnosis`. Furthermore, the column `subtype` in this table provides more insights into the samples of `neuroblastoma_molecular_subtypes.tsv` which had a subtype `NBL, to be classified`. If samples belong to **case 4** but didn't have a TPM value, those are subtyped as `Pathology-amp,Status-non-amp,TPM-NA`. 

11. `results/qc_table.tsv`: This table has matched samples from the TARGET and GMKF cohort. Samples were matched if they shared the same `Kids_First_Participant_ID` and `sample_id`. We specifically compare the `status` between each cohort and also compare their subtpyes. 

12. `results/molecular_subtypes_based_on_cutoff.tsv`: This table contains the biospecimens which were subtyped based on their TPM values.  

11. `plots/tpm_biospecimen_matching.png`: This file contains the plot of TPM vs Biospecimen_ID for those samples which had both DNA and RNA IDs. 


13. `plots/tpm_biospecimen_all_samples_with_tpm.png`:This file contains the plot of TPM vs Biospecimen_ID for those samples which had a TPM value. 

14. `plots/biospecimen_ID_Amp_Del.png`: The image files labeled in the following format `biospecimen_ID_Amp_Del.png` contain the chromosome 2 segment mean for that biospecimen.




