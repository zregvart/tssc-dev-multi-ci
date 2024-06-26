#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 

# buildah-rhtap
mkdir -p ./results

# Top level parameters 
export IMAGE=
export DOCKERFILE=
export CONTEXT=.
export TLSVERIFY=false
export BUILD_ARGS=""
export BUILD_ARGS_FILE=""


$SCRIPTDIR/verify-deps-exist 

function build() {
	echo "Running  build"
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
	
	BUILDAH_ARGS=()
	if [ -n "${BUILD_ARGS_FILE}" ]; then
	  BUILDAH_ARGS+=("--build-arg-file=${SOURCE_CODE_DIR}/${BUILD_ARGS_FILE}")
	fi
	
	for build_arg in "$@"; do
	  BUILDAH_ARGS+=("--build-arg=$build_arg")
	done
	
	# Build the image
	buildah build \
	  "${BUILDAH_ARGS[@]}" \
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
	buildah images --format '{{ .Name }}:{{ .Tag }}@{{ .Digest }}' | grep -v $IMAGE > ./results/BASE_IMAGES_DIGESTS
	cat /tmp/files/image-digest | tee ./results/IMAGE_DIGEST
	echo -n "$IMAGE" | tee ./results/IMAGE_URL
	
	# Save the image so it can be used in the generate-sbom step
	buildah push "$IMAGE" oci:/tmp/files/image
	
}

function generate-sboms() {
	echo "Running  generate-sboms"
	syft dir:$(workspaces.source.path)/source --output cyclonedx-json@1.5=/tmp/files/sbom-source.json
	syft oci-dir:/tmp/files/image --output cyclonedx-json@1.5=/tmp/files/sbom-image.json
	
}

function upload-sbom() {
	echo "Running  upload-sbom"
	cosign
}

# Task Steps 
build
generate-sboms
$SCRIPTDIR/merge-sboms.sh
upload-sbom
