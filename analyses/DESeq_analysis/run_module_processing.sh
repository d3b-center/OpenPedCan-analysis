#!/bin/bash
echo "Executing DESeq analysis"
sh ./run_deseq.sh
echo "Transform all individual JSON tables into a single JSONL file"
sh ./json_to_jsonl.sh