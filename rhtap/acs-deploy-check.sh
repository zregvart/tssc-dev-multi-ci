#!/bin/bash
# acs-deploy-check
mkdir -p ./results

# Top level parameters 
export ROX_CENTRAL_ENDPOINT=
export ROX_API_TOKEN=
export ACS_DEPLOY_CHECK_PARAM_VERBOSE=
export PARAM_INSECURE_SKIP_TLS_VERIFY=true

export PARAM_GITOPS_REPO_URL=

function rox-deploy-check() {
	echo "Running  rox-deploy-check"
	#!/usr/bin/env bash
	set +x
	
	if [ -z "$ROX_API_TOKEN" ]; then
		echo "ROX_API_TOKEN is not set, demo will exit with success"
		exit 0
	fi
	if [ -z "$ROX_CENTRAL_ENDPOINT" ]; then
		echo "ROX_CENTRAL_ENDPOINT is not set, demo will exit with success"
		exit 0
	fi
	
	echo "Using rox central endpoint ${ROX_CENTRAL_ENDPOINT}"
	
	# Clone gitops repository
	echo "Using gitops repository: ${PARAM_GITOPS_REPO_URL}"
	git clone "${PARAM_GITOPS_REPO_URL}" --single-branch --depth 1 gitops
	cd gitops
	echo "List of files in gitops repository root:"
	ls -al
	echo "List of components in the gitops repository:"
	ls -l components/
	
	echo "Download roxctl cli"
	if [ "${PARAM_INSECURE_SKIP_TLS_VERIFY}" = "true" ] ; then
	  curl_insecure='--insecure'
	fi
	curl $curl_insecure -s -L -H "Authorization: Bearer $ROX_API_TOKEN" \
	  "https://${ROX_CENTRAL_ENDPOINT}/api/cli/download/roxctl-linux" \
	  --output ./roxctl  \
	  > /dev/null
	if [ $? -ne 0 ]; then
	  echo 'Failed to download roxctl'
	  exit 1
	fi
	chmod +x ./roxctl  > /dev/null
	
	component_name=$(yq .metadata.name application.yaml)
	echo "Performing scan for ${component_name} component"
	file_to_check="components/${component_name}/base/deployment.yaml"
	if [ -f "$file_to_check" ]; then
	  echo "ROXCTL on $file_to_check"
	  ./roxctl deployment check \
	    $( [ "${PARAM_INSECURE_SKIP_TLS_VERIFY}" = "true" ] && echo -n "--insecure-skip-tls-verify") \
	    -e "${ROX_CENTRAL_ENDPOINT}" --file "$file_to_check" --output json \
	    > /tmp/roxctl_deployment_check_output.json
	  cp /tmp/roxctl_deployment_check_output.json /workspace/repository/acs-deploy-check.json
	else
	  echo "Failed to find file to check: $file_to_check"
	  exit 2
	fi
	
}

function report() {
	echo "Running  report"
	#!/usr/bin/env bash
	cat /workspace/repository/acs-deploy-check.json
	
}

# Task Steps  
rox-deploy-check
report
