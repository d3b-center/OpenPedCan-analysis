#!/usr/bin/env python


"""
00-search-ols-ontology-terms.py
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Functions to automate OLS search to retrieve ontology terms/codes for cancer_group
"""


__author__ = ('Sangeeta Shukla (shuklas1@chop.edu)')


import sys
import os
import requests
import json
import re
import pandas as pd
import argparse


def read_parameters():
     p = argparse.ArgumentParser(description=("Functions to automate OLS search to retrieve ontology terms/codes for cancer_group."), formatter_class=argparse.RawTextHelpFormatter)
     p.add_argument('INPUT_MAP_PREFILL', type=str, default=None, help="OPenPedCan efo-mondo-map-prefill file (efo-mondo-map-prefill.tsv)\n\n")
     p.add_argument('OLS_TERM_TYPE', type=str, default=None, help="OLS Term Type (EFO, MONDO, NCIT, UBERON, HP)\n\n")
     p.add_argument('OUT_FILE', type=str, default=None, help="Output file name\n\n")
     return p.parse_args()
   

def parse_input_for_ols_term_type(input_map_prefill, ols_term_type, URL):
  #load input prefilled file
  input_prefill=open(input_map_prefill, "r").read()
  cg_list=input_prefill.split("\n")
  cntr=1
  linesep="\t" #Define delimiter as tab or comma as found in input file
  
  cols = ["CancerGroup", "SearchTerm", "OntoID", "OntoDesc"]
  out_df = pd.DataFrame(columns=cols)
  
  print("Parsing to retrieve Term type: ", ols_term_type)
  
  for cgnum in range(1, len(cg_list)): #range starts at 1 skips the title
    cgl=cg_list[cgnum] #retrieve text in line cgnum
    cgrp=cgl.split(linesep) #split by delimiter
    
    if len(cgrp)>0:
      searchterm=cgrp[0]  #column number where cancer_group is found in input file
    
      searchterm = re.sub(r"\((.*?)\)", "", searchterm)  #Remove parenthesis 
      searchterm = re.sub(r"\[(.*?)\]", "", searchterm)  #Remove brackets
      searchterm = searchterm.replace('/',' ')  #Replace slash with white space
      
      searchterm=re.split('[,;]+', searchterm)  #Split, in case cancer group is compounded by multiple descriptors
      searchterm=searchterm[0]  #Fetch only first descriptor
      
      if searchterm !="":
        PARAMS={'q':searchterm, 'ontology':ols_term_type.lower(), 'rows':'1'}
        response = requests.get(url = URL, params = PARAMS)
        data = json.loads(response.text)
        if data['response']['docs']:
          ontoid=data['response']['docs'][0]['short_form']
          ontodesc=data['response']['docs'][0]['label']
          if searchterm.lower().strip('\"').__eq__(ontodesc.lower):
            outdata=[cgrp[0],searchterm, ontoid, ontodesc]
        else:
          outdata=[cgrp[0], searchterm, "Not found", "Not found"]

        out_df=out_df.append({"CancerGroup":outdata[0], "SearchTerm":outdata[1], "OntoID":outdata[2], "OntoDesc":outdata[3]},ignore_index=True)
        cntr=cntr+1
  return(out_df)
   
   
def main():
     # get input parameters
     args = read_parameters()
     URL="http://www.ebi.ac.uk/ols/api/search"  #use this one for API as of 17 Aug 2022
     
     
     # create module results directory
     results_dir = "results".format(os.path.dirname(__file__))
     
     # call function to automate parsing of cancer group to retrieve OLS Term ID
     ols_search_results = parse_input_for_ols_term_type(args.INPUT_MAP_PREFILL, args.OLS_TERM_TYPE, URL)
     
     # column names for result dataframe
     columns = ["cancer_group", "search_term", str(args.OLS_TERM_TYPE).lower()+"_code", str(args.OLS_TERM_TYPE).lower()+"_OntoDesc"]
     
     # write annotated CNV frequencies results to TSV file
     parsed_results = "{}/{}".format(results_dir,args.OUT_FILE)
     ols_search_results.to_csv(parsed_results, header=columns, index=None, sep='\t',encoding="utf-8", mode='w')
     print("Filename:", parsed_results," written")
     sys.exit(0)


if __name__ == "__main__":
     main()	
