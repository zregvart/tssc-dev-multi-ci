# show-sbom-rhdh

# Parameters 
export PARAM_IMAGE_URL=


function annotate-task() {
	echo "Running  annotate-task"
	#!/usr/bin/env bash
	
	# When this task is used in a pipelineRun triggered by Pipelines as Code, the annotations will be cleared,
	# so we're re-adding them here
	oc annotate taskrun $(context.taskRun.name) task.results.format=application/text
	oc annotate taskrun $(context.taskRun.name) task.results.key=LINK_TO_SBOM
	oc annotate taskrun $(context.taskRun.name) task.output.location=results
	
}

function show-sbom() {
	echo "Running  show-sbom"
	#!/bin/bash
	status=-1
	max_try=5
	wait_sec=2
	for run in $(seq 1 $max_try); do
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
	echo -n "$IMAGE_URL" > $(results.LINK_TO_SBOM.path)
	
}

# Task Steps 
annotate-task
show-sbom
