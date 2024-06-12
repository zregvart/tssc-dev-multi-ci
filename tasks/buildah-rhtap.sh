# buildah-rhtap

# Parameters 
export IMAGE=
export DOCKERFILE=
export CONTEXT=
export TLSVERIFY=
export BUILD_ARGS=
export BUILD_ARGS_FILE=


function build() {
build

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
buildah images --format '{{ .Name }}:{{ .Tag }}@{{ .Digest }}' | grep -v $IMAGE > $(results.BASE_IMAGES_DIGESTS.path)
cat /tmp/files/image-digest | tee $(results.IMAGE_DIGEST.path)
echo -n "$IMAGE" | tee $(results.IMAGE_URL.path)

# Save the image so it can be used in the generate-sbom step
buildah push "$IMAGE" oci:/tmp/files/image

}

function generate-sboms() {
generate-sboms

syft dir:$(workspaces.source.path)/source --output cyclonedx-json@1.5=/tmp/files/sbom-source.json
syft oci-dir:/tmp/files/image --output cyclonedx-json@1.5=/tmp/files/sbom-image.json

}

function merge-sboms() {
merge-sboms

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
upload-sbom

undefined
}

# Task Steps 
build
generate-sboms
merge-sboms
upload-sbom
