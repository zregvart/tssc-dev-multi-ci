#!/bin/bash
# acs-image-scan

# Top level parameters 
export ACS_IMAGE_SCAN_PARAM_ROX_SECRET_NAME=
export ACS_IMAGE_SCAN_PARAM_IMAGE=
export ACS_IMAGE_SCAN_PARAM_IMAGE_DIGEST=
export ACS_IMAGE_SCAN_PARAM_INSECURE_SKIP_TLS_VERIFY=


function annotate-task() {
	echo "Running  annotate-task"
	#!/usr/bin/env bash
	echo "acs-image-scan $(context.taskRun.name)"
	oc annotate taskrun $(context.taskRun.name) task.results.format=application/json
	oc annotate taskrun $(context.taskRun.name) task.results.type=roxctl-image-scan
	oc annotate taskrun $(context.taskRun.name) task.results.key=SCAN_OUTPUT
	oc annotate taskrun $(context.taskRun.name) task.results.container=step-report
	oc annotate taskrun $(context.taskRun.name) task.output.location=logs
	
}

function rox-image-scan() {
	echo "Running  rox-image-scan"
	#!/usr/bin/env bash
	set +x
	
	function set_test_output_result() {
	  local date=$(date +%s)
	  local result=${1:-ERROR}
	  local note=$2
	  local successes=${3:-0}
	  local failures=${4:-0}
	  local warnings=${5:-0}
	  echo "{\"result\":\"${result}\",\"timestamp\":\"${date}\",\"note\":\"${note}\",\"namespace\":\"default\",\"successes\":\"${successes}\",\"failures\":\"${failures}\",\"warnings\":\"${warnings}\"}" \
	    | tee $(results.TEST_OUTPUT.path)
	}
	
	# Check if rox API enpoint is configured
	if test -f /rox-secret/rox-api-endpoint ; then
	  export ROX_CENTRAL_ENDPOINT=$(</rox-secret/rox-api-endpoint)
	else
	  echo "rox API endpoint is not set, demo will exit with success"
	  echo "TODO: configure the pipeline with your ACS server domain. Set your ACS endpoint under 'rox-api-endpoint' key in the secret specified in rox-secret-name parameter. For example: 'rox.stackrox.io:443'"
	  set_test_output_result SKIPPED "Task $(context.task.name) skipped: ACS API enpoint not specified"
	  exit 0
	fi
	
	# Check if rox API token is configured
	if test -f /rox-secret/rox-api-token ; then
	  export ROX_API_TOKEN=$(</rox-secret/rox-api-token)
	else
	  echo "rox API token is not set, demo will exit with success"
	  echo "TODO: configure the pipeline to have access to ROXCTL. Set you ACS token under 'rox-api-token' key in the secret specified in rox-secret-name parameter."
	  set_test_output_result SKIPPED "Task $(context.task.name) skipped: ACS API token not provided"
	  exit 0
	fi
	
	echo "Using rox central endpoint ${ROX_CENTRAL_ENDPOINT}"
	
	echo "Download roxctl cli"
	if [ "${PARAM_INSECURE_SKIP_TLS_VERIFY}" = "true" ] ; then
	  curl_insecure='--insecure'
	fi
	curl $curl_insecure -s -L -H "Authorization: Bearer $ROX_API_TOKEN" \
	  "https://${ROX_CENTRAL_ENDPOINT}/api/cli/download/roxctl-linux" \
	  --output ./roxctl  \
	  > /dev/null
	if [ $? -ne 0 ]; then
	  note='Failed to download roxctl'
	  echo $note
	  set_test_output_result ERROR "$note"
	  exit 1
	fi
	chmod +x ./roxctl  > /dev/null
	
	echo "roxctl image scan"
	
	IMAGE=${PARAM_IMAGE}@${PARAM_IMAGE_DIGEST}
	./roxctl image scan \
	  $( [ "${PARAM_INSECURE_SKIP_TLS_VERIFY}" = "true" ] && \
	  echo -n "--insecure-skip-tls-verify") \
	  -e "${ROX_CENTRAL_ENDPOINT}" --image "$IMAGE" --output json --force \
	  > roxctl_image_scan_output.json
	image_scan_err_code=$?
	cp roxctl_image_scan_output.json /steps-shared-folder/acs-image-scan.json
	if [ $image_scan_err_code -ne 0 ]; then
	  cat roxctl_image_scan_output.json
	  note='ACS image scan failed to process the image. See the task logs for more details.'
	  echo $note
	  set_test_output_result ERROR "$note"
	  exit 2
	fi
	
	# Set SCAN_OUTPUT result
	critical=$(cat roxctl_image_scan_output.json | grep -oP '(?<="CRITICAL": )\d+')
	high=$(cat roxctl_image_scan_output.json | grep -oP '(?<="IMPORTANT": )\d+')
	medium=$(cat roxctl_image_scan_output.json | grep -oP '(?<="MODERATE": )\d+')
	low=$(cat roxctl_image_scan_output.json | grep -oP '(?<="LOW": )\d+')
	echo "{\"vulnerabilities\":{\"critical\":${critical},\"high\":${high},\"medium\":${medium},\"low\":${low}}}" | tee $(results.SCAN_OUTPUT.path)
	
	# Set TEST_OUTPUT result
	if [[ -n "$critical" && "$critical" -eq 0 && "$high" -eq 0 && "$medium" -eq 0 && "$low" -eq 0 ]]; then
	  note="Task $(context.task.name) completed. No vulnerabilities found."
	else
	  note="Task $(context.task.name) completed: Refer to Tekton task result SCAN_OUTPUT for found vulnerabilities."
	fi
	set_test_output_result SUCCESS "$note"
	
}

function report() {
	echo "Running  report"
	#!/usr/bin/env bash
	cat /steps-shared-folder/acs-image-scan.json
	
}

# Task Steps 
annotate-task
rox-image-scan
report
