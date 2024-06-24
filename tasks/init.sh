# init

# Top level parameters 
export INIT_PARAM_IMAGE_URL=
export INIT_PARAM_REBUILD=
export INIT_PARAM_SKIP_CHECKS=


function init() {
	echo "Running  init"
	#!/bin/bash
	echo "Build Initialize: $IMAGE_URL"
	echo
	
	echo "Determine if Image Already Exists"
	# Build the image when rebuild is set to true or image does not exist
	# The image check comes last to avoid unnecessary, slow API calls
	if [ "$REBUILD" == "true" ] || [ "$SKIP_CHECKS" == "false" ] || ! oc image info $IMAGE_URL &>/dev/null; then
	  echo -n "true" > $(results.build.path)
	else
	  echo -n "false" > $(results.build.path)
	fi
	
}

# Task Steps 
init
