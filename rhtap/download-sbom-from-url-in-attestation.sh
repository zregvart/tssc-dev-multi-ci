#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Get the SBOM for an image by downloading the OCI blob referenced in the image attestation.
#
# The input to this script (The `IMAGES` env var) is a JSON string in the same format as the output
# of the gather-deploy-images.sh script:
#
#     {
#       "components": [
#         {"containerImage": "<image reference>"},
#         {"containerImage": "<image reference>"}
#         ...
#       ]
#     }
#
# For each image, the task will:
# * Download the provenance attestation using `cosign verify-attestation`
# * Find the SBOM_BLOB_URL Tekton result in the attestation
# * Download the OCI blob referenced by the url.
#
# The task saves the SBOMs to `${SBOMS_DIR}/${image_reference}/sbom.json`. The image references
# are taken verbatim from the input object. For example, the output files could be:
#
#     sboms-workspace/registry.example.org/namespace/foo:v1.0.0/sbom.json
#     sboms-workspace/registry.example.org/namespace/bar@sha256:<checksum>/sbom.json

# Check required variables
: "${IMAGES:?}"

# Set defaults for unset optional variables
: "${SBOMS_DIR=.}"  # TODO: in the Tekton task, this is relative to a shared workspace. Where should this go?
: "${HTTP_RETRIES=3}"
: "${PUBLIC_KEY=}"
: "${REKOR_HOST=}"
: "${IGNORE_REKOR=false}"
: "${TUF_MIRROR=}"

# Set script-local variables
WORKDIR=$(mktemp -d --tmpdir "download-sbom-workdir.XXXXXX")

if [[ -z "$PUBLIC_KEY" ]]; then
    echo "No public key set, cannot verify attestation." >&2
    exit 1
fi

cosign_args=(--key "$PUBLIC_KEY")

if [[ -n "$REKOR_HOST" ]]; then
    cosign_args+=(--rekor-url "$REKOR_HOST")
elif [[ "$IGNORE_REKOR" = "true" ]]; then
    cosign_args+=(--insecure-ignore-tlog)
else
    cosign_args+=()
fi

if [[ -n "${TUF_MIRROR:-}" ]]; then
    echo 'Initializing TUF root...'
    cosign initialize --mirror "${TUF_MIRROR}" --root "${TUF_MIRROR}/root.json"
fi

jq -r '.components[].containerImage' <<< "$IMAGES" | while read -r image; do
    echo "Getting attestation for $image"
    mkdir -p "$WORKDIR/$image"
    cosign verify-attestation \
        --type slsaprovenance \
        "${cosign_args[@]}" \
        "$image" > "$WORKDIR/$image/attestation.json"
done

get_from_www_auth_header() {
    local www_authenticate=$1
    local key=$2
    # shellcheck disable=SC2001
    # E.g.
    #   www_authenticate='Bearer realm="https://ghcr.io/token",service="ghcr.io"'
    #   key=service
    #   -> ghcr.io
    sed "s/.*$key=\"\([^\"]*\)\".*/\1/" <<< "$www_authenticate"
}

get_container_auth() {
    # https://man.archlinux.org/man/containers-auth.json.5

    local image=$1

    local runtime_dir="${XDG_RUNTIME_DIR:-}"
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    if [[ -n "$runtime_dir" ]]; then
        default_authfile="${runtime_dir}/containers/auth.json"
    else
        default_authfile="$config_home/containers/auth.json"
    fi

    local maybe_auth_files=(
        "$default_authfile"
        "$config_home/containers/auth.json"
        "$HOME/.docker/config.json"
        "$HOME/.dockercfg"
    )
    local auth_files=()
    for file in "${maybe_auth_files[@]}"; do
        if [[ -r "$file" ]]; then
            auth_files+=("$file")
        fi
    done

    # registry.com/namespace/repo@sha256:digest -> registry.com/namespace/repo
    local auth_key=${image%@*}

    while true; do
        for auth_file in "${auth_files[@]}"; do
            if jq -r -e --arg key "$auth_key" '.auths[$key].auth // empty' "$auth_file"; then
                echo "Found auth for $auth_key in $auth_file" >&2
                return 0
            fi
        done

        # Try less specific key, e.g. registry.com/namespace/repo -> registry.com/namespace
        local new_key=${auth_key%/*}
        if [[ "$new_key" = "$auth_key" ]]; then
            # Already tried all possible keys, no auth found
            echo "No auth found for $auth_key" >&2
            return 1
        fi

        auth_key=$new_key
    done

}

download_blob() {
    local blob_ref=$1
    local dest=$2

    # convert:
    #     registry.com/namespace/repo@sha256:digest
    # ->  https://registry.com/v2/namespace/repo/blobs/sha256:digest
    blob_url=$(sed -E 's;([^/]*)/(.*)@(.*);https://\1/v2/\2/blobs/\3;' <<< "$blob_ref")

    local tmp_dest
    tmp_dest=$(mktemp --tmpdir download-sbom-task.out.XXXXXX)

    local headers_file
    headers_file=$(mktemp --tmpdir download-sbom-task.headers.XXXXXX)

    local common_curl_opts=(--silent --show-error --retry "${HTTP_RETRIES:-3}")

    echo "GET $blob_url" >&2
    local response_code
    response_code=$(curl \
        "${common_curl_opts[@]}" \
        -L \
        --write-out '%{response_code}' \
        --output "$tmp_dest" \
        --dump-header "$headers_file" \
        "$blob_url"
    )

    if [[ "$response_code" -eq 200 ]]; then
        # Blob download didn't require auth, we're done
        :
    elif [[ "$response_code" -eq 401 ]]; then
        echo "Got 401, trying to authenticate" >&2

        local www_authenticate
        www_authenticate=$(sed -n 's/^www-authenticate:\s*//ip' "$headers_file")

        local realm service scope token_url
        realm=$(get_from_www_auth_header "$www_authenticate" realm)
        service=$(get_from_www_auth_header "$www_authenticate" service)
        scope=$(get_from_www_auth_header "$www_authenticate" scope)
        token_url=$(jq -n -r --arg realm "$realm" --arg service "$service" --arg scope "$scope" \
            '"\($realm)?service=\($service | @uri)&scope=\($scope | @uri)"'
        )

        local basic_auth token_auth
        if basic_auth=$(get_container_auth "$blob_ref"); then
            token_auth=(-H "authorization: Basic $basic_auth")
        else
            echo "Trying to get token anonymously" >&2
            token_auth=()
        fi

        echo "GET $token_url" >&2
        token=$(curl \
            "${common_curl_opts[@]}" \
            "${token_auth[@]}" \
            --fail \
            "$token_url" | jq -r .token
        )

        echo "GET $blob_url" >&2
        curl \
            "${common_curl_opts[@]}" \
            -L \
            --output "$tmp_dest" \
            --fail \
            -H "authorization: Bearer $token" \
            "$blob_url"
    else
        echo "Error: unexpected response code: $response_code!" >&2
        return 1
    fi

    cp "$tmp_dest" "$dest"
}

find_blob_url() {
    local attestation_file=$1

    jq -r --slurp < "$attestation_file" '
      map(
        .payload | @base64d | fromjson |
        .. | select(.name? == "SBOM_BLOB_URL") | .value // empty
      ) |
      unique |
      if length == 1 then
        first
      else
        error("Expected to find exactly one SBOM_BLOB_URL result, found \(length): \(.)")
      end'
}

jq -r '.components[].containerImage' <<< "$IMAGES" | while read -r image; do
    echo "Looking for SBOM_BLOB_URL result in the attestation for $image"
    attestation_file="$WORKDIR/$image/attestation.json"
    sbom_blob_url=$(find_blob_url "$attestation_file")
    mkdir -p "$SBOMS_DIR/$image"
    download_blob "$sbom_blob_url" "$SBOMS_DIR/$image/sbom.json"
done
