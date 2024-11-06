#
# Create attestation predicate for RHTAP GitLab builds
#
# Useful references:
# - https://slsa.dev/spec/v1.0/provenance
# - https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
#
yq -o=json -I=0 << EOT
---
buildDefinition:
  buildType: "https://redhat.com/rhtap/slsa-build-types/${CI_TYPE}-build/v1"
  externalParameters: {}
  internalParameters: {}
  resolvedDependencies:
    - uri: "git+${GIT_URL}"
      digest:
        gitCommit: "${GIT_COMMIT}"

runDetails:
  builder:
    # Todo:
    id: ~
    builderDependencies: []
    version: {}

  metadata:
    startedOn: "$(cat $BASE_RESULTS/init/START_TIME)"
    # Inaccurate, but maybe close enough
    finishedOn: "$(timestamp)"

  byproducts:
    - name: SBOM_BLOB
      uri: "$(cat "$BASE_RESULTS"/buildah-rhtap/SBOM_BLOB_URL)"

EOT
