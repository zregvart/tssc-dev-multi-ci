#!/bin/bash
# summary

# Top level parameters 
export SUMMARY_PARAM_PIPELINERUN_NAME=
export SUMMARY_PARAM_GIT_URL=
export SUMMARY_PARAM_IMAGE_URL=
export SUMMARY_PARAM_BUILD_TASK_STATUS=


function appstudio-summary() {
	echo "Running  appstudio-summary"
	#!/usr/bin/env bash
	echo
	echo "Build Summary:"
	echo
	echo "Build repository: $GIT_URL"
	if [ "$BUILD_TASK_STATUS" == "Succeeded" ]; then
	  echo "Generated Image is in : $IMAGE_URL"
	fi
	if [ -e "$SOURCE_BUILD_RESULT_FILE" ]; then
	  url=$(jq -r ".image_url" <"$SOURCE_BUILD_RESULT_FILE")
	  echo "Generated Source Image is in : $url"
	fi
	echo
	echo End Summary
	
}

# Task Steps 
appstudio-summary
