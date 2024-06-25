#!/bin/bash
# acs-image-check
mkdir -p ./results

# Top level parameters 
export ACS_IMAGE_CHECK_PARAM_ROX_SECRET_NAME=
export ACS_IMAGE_CHECK_PARAM_IMAGE=
export ACS_IMAGE_CHECK_PARAM_INSECURE_SKIP_TLS_VERIFY=
export ACS_IMAGE_CHECK_PARAM_IMAGE_DIGEST=


function annotate-task() {
	echo "Running  annotate-task"
	#!/usr/bin/env bash
	echo "acs-image-scan $(context.taskRun.name)"
	oc annotate taskrun $(context.taskRun.name) task.results.format=application/json
	oc annotate taskrun $(context.taskRun.name) task.results.type=roxctl-image-check
	oc annotate taskrun $(context.taskRun.name) task.results.container=step-report
	oc annotate taskrun $(context.taskRun.name) task.output.location=logs
	
}

function rox-image-check() {
	echo "Running  rox-image-check"
	#!/usr/bin/env bash
	set +x
	
	# Check if rox API enpoint is configured
	if test -f /rox-secret/rox-api-endpoint ; then
	  export ROX_CENTRAL_ENDPOINT=$(</rox-secret/rox-api-endpoint)
	else
	  echo "rox API endpoint is not set, demo will exit with success"
	  echo "TODO: configure the pipeline with your ACS server domain. Set your ACS endpoint under 'rox-api-endpoint' key in the secret specified in rox-secret-name parameter. For example: 'rox.stackrox.io:443'"
	  exit 0
	fi
	
	# Check if rox API token is configured
	if test -f /rox-secret/rox-api-token ; then
	  export ROX_API_TOKEN=$(</rox-secret/rox-api-token)
	else
	  echo "rox API token is not set, demo will exit with success"
	  echo "TODO: configure the pipeline to have access to ROXCTL. Set you ACS token under 'rox-api-token' key in the secret specified in rox-secret-name parameter."
	  exit 0
	fi
	
	echo "Using rox central endpoint ${ROX_CENTRAL_ENDPOINT}"
	
	echo "Download roxctl cli"
	if [ "${PARAM_INSECURE_SKIP_TLS_VERIFY}" = "true" ]; then
	  curl_insecure='--insecure'
	fi
	curl $curl_insecure -s -L -H "Authorization: Bearer $ROX_API_TOKEN" \
	  "https://${ROX_CENTRAL_ENDPOINT}/api/cli/download/roxctl-linux" \
	  --output ./roxctl \
	  > /dev/null
	if [ $? -ne 0 ]; then
	  echo 'Failed to download roxctl'
	  exit 1
	fi
	received_filesize=$(stat -c%s ./roxctl)
	if (( $received_filesize < 10000 )); then
	  # Responce from ACS server is not a binary but error message
	  cat ./roxctl
	  echo 'Failed to download roxctl'
	  exit 2
	fi
	chmod +x ./roxctl  > /dev/null
	
	echo "roxctl image check"
	IMAGE=${PARAM_IMAGE}@${PARAM_IMAGE_DIGEST}
	./roxctl image check \
	  $( [ "${PARAM_INSECURE_SKIP_TLS_VERIFY}" = "true" ] && \
	  echo -n "--insecure-skip-tls-verify") \
	  -e "${ROX_CENTRAL_ENDPOINT}" --image "$IMAGE" --output json --force \
	  > roxctl_image_check_output.json
	cp roxctl_image_check_output.json /steps-shared-folder/acs-image-check.json
	
}

function report() {
	echo "Running  report"
	#!/usr/bin/env bash
	cat /steps-shared-folder/acs-image-check.json
	
}

# Task Steps 
annotate-task
rox-image-check
report
