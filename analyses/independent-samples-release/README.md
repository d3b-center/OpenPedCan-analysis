# Independent Samples

## Summary

Many analyses that involve mutation frequencies or co-occurence require that all samples be independent.
However, the OpenPedCan data set includes many cases where multiple speciments were taken from a single individual.
This analysis creates lists of samples such that there are no cases where more than one specimen is included from each individual.

As different analyses may require different sets of data, we actually generate a few different sets, stored in the `results` subdirectory:
* Primary specimens only with whole genome sequence (WGS):  
`independent-specimens.wgs.primary.tsv`
* Primary and secondary specimens with WGS:  
`independent-specimens.wgs.primary-plus.tsv`
* Primary specimens only with WGS, whole exome sequence (WXS), or Targeted Sequencng (panel):  
`independent-specimens.wgswxspanel.primary.tsv`
* Primary and secondary specimens with WGS, WXS, or panel:  
`independent-specimens.wgswxspanel.primary-plus.tsv`
* Primary and secondary specimens matching WGS, WXS, or panel independent `sample_id` plus only-RNA-Seq
independent-specimens.rnaseq.primary-plus.tsv


## Generating sample lists

To generate the independent sample lists and associated analysis of redundancies in the overall data set, run the following script from the project root directory:

Use `OPENPBTA_BASE_RELEASE=1` to run this module using the `histologies-base.tsv` from data folder while preparing analysis files for release:

```sh
OPENPBTA_BASE_RELEASE=1 ../analyses/independent-samples-release/run-independent-samples.sh 
```

OR by default uses pbta-histologies.tsv from data folder
```sh
bash analyses/independent-samples-release/run-independent-samples.sh
```



## Methods

For WGS-preferred lists, when a `Kids_First_Participant_ID` is associated with multiple `experimental_strategy` values i.e. `WGS`, `WXS` or `Targeted Sequencing`, priority is given to a single randomly chosen `WGS` biospecimen first, followed by either a single randomly chosen `WXS` or `Targeted Sequencing` sample.
There is also a preference for the earliest collected samples, but as this data is not currently available, that code is not currently relevant.

When multiple RNA-Seq samples exist per participant, the script matches the independent whole genome or whole exome sample_ids to gather matched RNA-Seq sample. If participant has onle RNA-Seq sample then a primary (and secondary if applicable) sample is randomly selected per participant  

## Relevant links
The methods are described in the manuscript here:
 https://github.com/AlexsLemonade/OpenPBTA-manuscript/blob/master/content/03.methods.md#selection-of-independent-samples

