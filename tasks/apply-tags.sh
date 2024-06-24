#!/bin/bash
# apply-tags

# Top level parameters 
export APPLY_TAGS_PARAM_IMAGE=
export APPLY_TAGS_PARAM_ADDITIONAL_TAGS=


function apply-additional-tags-from-parameter() {
	echo "Running  apply-additional-tags-from-parameter"
	#!/bin/bash
	
	if [ "$#" -ne 0 ]; then
	  IMAGE_WITHOUT_TAG=$(echo "$IMAGE" | sed 's/:[^:]*$//')
	  for tag in "$@"; do
	    echo "Applying tag $tag"
	    skopeo copy docker://$IMAGE docker://$IMAGE_WITHOUT_TAG:$tag
	  done
	else
	  echo "No additional tags parameter specified"
	fi
	
}

function apply-additional-tags-from-image-label() {
	echo "Running  apply-additional-tags-from-image-label"
	#!/bin/bash
	
	ADDITIONAL_TAGS_FROM_IMAGE_LABEL=$(skopeo inspect --format '{{ index .Labels "konflux.additional-tags" }}' docker://$IMAGE)
	
	if [ -n "${ADDITIONAL_TAGS_FROM_IMAGE_LABEL}" ]; then
	  IFS=', ' read -r -a tags_array <<< "$ADDITIONAL_TAGS_FROM_IMAGE_LABEL"
	
	  IMAGE_WITHOUT_TAG=$(echo "$IMAGE" | sed 's/:[^:]*$//')
	  for tag in "${tags_array[@]}"
	  do
	      echo "Applying tag $tag"
	      skopeo copy docker://$IMAGE docker://$IMAGE_WITHOUT_TAG:$tag
	  done
	else
	  echo "No additional tags specified in the image labels"
	fi
	
}

# Task Steps 
apply-additional-tags-from-parameter
apply-additional-tags-from-image-label
