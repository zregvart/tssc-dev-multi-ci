#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# buildah-rhtap
source $SCRIPTDIR/common.sh

# Top level parameters 

function build() {
	echo "Running $TASK_NAME:build"
	# Check if the Dockerfile exists
	SOURCE_CODE_DIR=source
	if [ -e "$SOURCE_CODE_DIR/$CONTEXT/$DOCKERFILE" ]; then
	  dockerfile_path="$SOURCE_CODE_DIR/$CONTEXT/$DOCKERFILE"
	elif [ -e "$SOURCE_CODE_DIR/$DOCKERFILE" ]; then
	  dockerfile_path="$SOURCE_CODE_DIR/$DOCKERFILE"
	else
	  echo "Cannot find Dockerfile $DOCKERFILE"
	  exit 1
	fi
	
	# Build the image
	buildah build \
	  --tls-verify=$TLSVERIFY \
	  --ulimit nofile=4096:4096 \
	  -f "$dockerfile_path" -t $IMAGE $SOURCE_CODE_DIR/$CONTEXT
	
	# Push the image
	buildah push \
	  --tls-verify=$TLSVERIFY \
	  --retry=5 \
	  --digestfile /tmp/files/image-digest $IMAGE \
	  docker://$IMAGE
	
	# Set task results
	buildah images --format '{{ .Name }}:{{ .Tag }}@{{ .Digest }}' | grep -v $IMAGE > $RESULTS/BASE_IMAGES_DIGESTS
	cat /tmp/files/image-digest | tee $RESULTS/IMAGE_DIGEST
	echo -n "$IMAGE" | tee $RESULTS/IMAGE_URL
	
	# Save the image so it can be used in the generate-sbom step
	buildah push "$IMAGE" oci:/tmp/files/image
	
}

function generate-sboms() {
	echo "Running $TASK_NAME:generate-sboms"
	syft dir:$(workspaces.source.path)/source --output cyclonedx-json@1.5=/tmp/files/sbom-source.json
	syft oci-dir:/tmp/files/image --output cyclonedx-json@1.5=/tmp/files/sbom-image.json
	
}

function merge-sboms() {
	echo "Running $TASK_NAME:merge-sboms"
	#!/bin/python3
	import hashlib
	import json
	import os
	import re
	
	### load SBOMs ###
	
	with open("./sbom-image.json") as f:
	  image_sbom = json.load(f)
	
	with open("./sbom-source.json") as f:
	  source_sbom = json.load(f)
	
	
	### attempt to deduplicate components ###
	
	component_list = image_sbom.get("components", [])
	existing_purls = [c["purl"] for c in component_list if "purl" in c]
	
	for component in source_sbom.get("components", []):
	  if "purl" in component:
	    if component["purl"] not in existing_purls:
	      component_list.append(component)
	      existing_purls.append(component["purl"])
	  else:
	    # We won't try to deduplicate components that lack a purl.
	    # This should only happen with operating-system type components,
	    # which are only reported in the image SBOM.
	    component_list.append(component)
	
	component_list.sort(key=lambda c: c["type"] + c["name"])
	image_sbom["components"] = component_list
	
	
	### write the CycloneDX unified SBOM ###
	
	with open("./sbom-cyclonedx.json", "w") as f:
	  json.dump(image_sbom, f, indent=4)
	
	
	### write the SBOM blob URL result ###
	
	with open("./sbom-cyclonedx.json", "rb") as f:
	  sbom_digest = hashlib.file_digest(f, "sha256").hexdigest()
	
	# https://github.com/opencontainers/distribution-spec/blob/main/spec.md?plain=1#L160
	tag_regex = "[a-zA-Z0-9_][a-zA-Z0-9._-]{0,127}"
	
	# the tag must be after a colon, but always at the end of the string
	# this avoids conflict with port numbers
	image_without_tag = re.sub(f":{tag_regex}$", "", os.getenv("IMAGE"))
	
	sbom_blob_url = f"{image_without_tag}@sha256:{sbom_digest}"
	
	with open(os.getenv("RESULT_PATH"), "w") as f:
	  f.write(sbom_blob_url)
	
}

function upload-sbom() {
	echo "Running $TASK_NAME:upload-sbom"
	cosign
}

# Task Steps 
build
generate-sboms
merge-sboms
upload-sbom
