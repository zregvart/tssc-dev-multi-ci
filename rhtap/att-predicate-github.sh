#
# Create attestation predicate for RHTAP GitHub builds
#
# Useful references:
# - https://slsa.dev/spec/v1.0/provenance
# - https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables#default-environment-variables
#
yq -o=json -I=0 <<EOT
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
