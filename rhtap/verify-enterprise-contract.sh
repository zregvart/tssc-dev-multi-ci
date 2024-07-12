#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# verify-enterprise-contract
source $SCRIPTDIR/common.sh

# Top level parameters 

function version() {
	echo "Running $TASK_NAME:version"
	ec version  
}

function initialize-tuf() {
	echo "Running $TASK_NAME:initialize-tuf"
	set -euo pipefail
	
	if [[ -z "${TUF_MIRROR:-}" ]]; then
	    echo 'TUF_MIRROR not set. Skipping TUF root initialization.'
	else 
		echo 'Initializing TUF root...'
		cosign initialize --mirror "${TUF_MIRROR}" --root "${TUF_MIRROR}/root.json"
		echo 'Done!'
	fi
}

function validate() {
	echo "Running $TASK_NAME:validate"
	
	IMAGES=$(cat $BASE_RESULTS/gather-deploy-images/IMAGES_TO_VERIFY)
	echo "Images to Verify "
	cat $BASE_RESULTS/gather-deploy-images/IMAGES_TO_VERIFY | jq  
	ec "$IMAGES" \
          "--policy" \
          "$POLICY_CONFIGURATION" \
          "--public-key" \
          "$PUBLIC_KEY" \
          "--rekor-url" \
          "$REKOR_HOST" \
          "--ignore-rekor=$IGNORE_REKOR" \
          "--info=$INFO" \
          "--strict=false" \
          "--show-successes" \
          "--effective-time=$EFFECTIVE_TIME \
          "--output" \ 
          "yaml=$HOMEDIR/report.yaml" \
          "--output" \
          "appstudio=$RESULTS/TEST_OUTPUT" \
          "--output" \
          "json=$HOMEDIR/report-json.json"
}

function report() {
	echo "Running $TASK_NAME:report"
	cat "$HOMEDIR/report.yaml" 

function report-json() {
	echo "Running $TASK_NAME:report-json"
	cat  "$HOMEDIR/report-json.json" 
}

function summary() {
	echo "Running $TASK_NAME:summary"
	jq "." "$RESULTS/TEST_OUTPUT" 
}

function assert() {
	echo "Running $TASK_NAME:assert"
	jq --argjson strict "$STRICT" -e" \
        ".result == \"SUCCESS\" or .result == \"WARNING\" or ($strict | not)\n" \
          "$RESULTS/TEST_OUTPUT"
}
  
# Task Steps 
version
initialize-tuf
validate
report
report-json
summary
assert 
exit_with_success_result
