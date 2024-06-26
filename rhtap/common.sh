#!/bin/bash
# Vars for scrips

export TASK_NAME=$(basename $0 .sh)
export RESULTS=./results/$TASK_NAME
mkdir -p $RESULTS
echo 
echo "Step: $TASK_NAME"
echo "Results: $RESULTS"
