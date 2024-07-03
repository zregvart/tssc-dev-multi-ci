#!/bin/bash
# Vars for scripts

DIR=$(pwd)
export TASK_NAME=$(basename $0 .sh)
export RESULTS=$DIR/results/$TASK_NAME
export TEMP_DIR=$DIR/results/temp 
mkdir -p $RESULTS
mkdir -p $TEMP_DIR
mkdir -p $TEMP_DIR/files
echo 
echo "Step: $TASK_NAME"
echo "Results: $RESULTS"

export PATH=$PATH:/usr/local/bin 

export IMAGE_URL=quay.io/jduimovich0/bootstrap
export IMAGE=$IMAGE_URL
export RESULT_PATH=$DIR/results/temp/files/sbom-url
#export XDG_RUNTIME_DIR=/home/john/dev/auth-creds

