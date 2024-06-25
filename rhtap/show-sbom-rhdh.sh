#!/bin/bash
# show-sbom-rhdh
mkdir -p ./results

# Top level parameters 
export IMAGE_URL=

function show-sbom() {
	echo "Running  show-sbom"
	#!/bin/bash
	status=-1
	max_try=5
	wait_sec=2
	for run in $(seq 1 $max_try); do
      echo -n "."
	  status=0
	  cosign download sbom $IMAGE_URL 2>>err
	  status=$?
	  if [ "$status" -eq 0 ]; then
	    break
	  fi
	  sleep $wait_sec
	done
	if [ "$status" -ne 0 ]; then
	    echo "Failed to get SBOM after ${max_try} tries" >&2
	    cat err >&2
	fi
	
	# This result will be ignored by RHDH, but having it set is actually necessary for the task to be properly
	# identified. For now, we're adding the image URL to the result so it won't be empty.
	echo -n "$IMAGE_URL" > ./results/LINK_TO_SBOM
	
}

# Task Steps  
show-sbom
