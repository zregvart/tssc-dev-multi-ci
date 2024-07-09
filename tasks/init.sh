#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# init
source $SCRIPTDIR/common.sh

# Top level parameters 

function init() {
	echo "Running $TASK_NAME:init"
	#!/bin/bash
	echo "Build Initialize: $IMAGE_URL"
	echo
	
	echo "Determine if Image Already Exists"
	# Build the image when image does not exists or rebuild is set to true
	if ! oc image info $IMAGE_URL &>/dev/null || [ "$REBUILD" == "true" ] || [ "$SKIP_CHECKS" == "false" ]; then
	  echo -n "true" > $RESULTS/build
	else
	  echo -n "false" > $RESULTS/build
	fi
	
}

# Task Steps 
init
