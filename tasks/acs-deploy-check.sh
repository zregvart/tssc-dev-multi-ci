# acs-deploy-check

# Parameters 
export PARAM_ROX_SECRET_NAME=
export PARAM_GITOPS_REPO_URL=
export PARAM_VERBOSE=
export PARAM_INSECURE_SKIP_TLS_VERIFY=


function annotate-task() {
	echo "Running  annotate-task"
	#!/usr/bin/env bash
	echo "acs-image-scan $(context.taskRun.name)"
	oc annotate taskrun $(context.taskRun.name) task.results.format=application/json
	oc annotate taskrun $(context.taskRun.name) task.results.type=roxctl-deployment-check
	oc annotate taskrun $(context.taskRun.name) task.results.container=step-report
	oc annotate taskrun $(context.taskRun.name) task.output.location=logs
	
}

function rox-deploy-check() {
	echo "Running  rox-deploy-check"
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
annotate-task
rox-deploy-check
report
