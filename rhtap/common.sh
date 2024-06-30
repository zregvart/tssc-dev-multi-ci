#!/bin/bash
# Vars for scrips

export TASK_NAME=$(basename $0 .sh)
export RESULTS=./results/$TASK_NAME
export TEMP_DIR=./results/temp
mkdir -p $RESULTS
echo 
echo "Step: $TASK_NAME"
echo "Results: $RESULTS"

export PATH=$PATH:/usr/local/bin 