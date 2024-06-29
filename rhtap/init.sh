#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 

source $SCRIPTDIR/common.sh

REQUIRED_BINARY="git curl jq yq buildah syft cosign roxctl"
#REQUIRED_BINARY+=" roxctl"
REQUIRED_ENV="" 
rhtap/verify-deps-exist "$REQUIRED_ENV" "$REQUIRED_BINARY" 

# Top level parameters 
export INIT_PARAM_IMAGE_URL=
export INIT_PARAM_REBUILD=
export INIT_PARAM_SKIP_CHECKS=


function init() {
	echo "Running $TASK_NAME:init"
	#!/bin/bash
	echo "Build Initialize: $IMAGE_URL" 	
	echo "Determine if Image Already Exists"
	# Build the image when rebuild is set to true or image does not exist
	# The image check comes last to avoid unnecessary, slow API calls
	if [ "$REBUILD" == "true" ] || [ "$SKIP_CHECKS" == "false" ] || ! oc image info $IMAGE_URL &>/dev/null; then
	  echo -n "true" > $RESULTS/build
	else
	  echo -n "false" > $RESULTS/build
	fi
	
}

# Task Steps 
init
