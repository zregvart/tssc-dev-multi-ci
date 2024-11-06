#
# Base image for use as a step runner for RHTAP pipelines
#

FROM docker.io/redhat/ubi9-minimal:9.4

# Todo:
# - Pin all the versions (maybe)
# - Don't hard code the arch and platform in curl downloads
# - Use RH builds instead of upstream where possible
# - Check the sigature files for the curl downloads

RUN \
  microdnf upgrade --assumeyes --nodocs --setopt=keepcache=0 --refresh && \
  microdnf -y --nodocs --setopt=keepcache=0 install which git-core jq python3.11 podman buildah podman fuse-overlayfs && \
  ln -s /usr/bin/python3.11 /usr/bin/python3

RUN \
  curl -sL https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64 -o /usr/bin/yq && chmod 755 /usr/bin/yq && \
  curl -sL https://github.com/sigstore/cosign/releases/download/v2.4.1/cosign-linux-amd64 -o /usr/bin/cosign && chmod 755 /usr/bin/cosign && \
  curl -sL https://github.com/enterprise-contract/ec-cli/releases/download/v0.6.58/ec_linux_amd64 -o /usr/bin/ec && chmod 755 /usr/bin/ec && \
  curl -sL https://github.com/anchore/syft/releases/download/v1.14.1/syft_1.14.1_linux_amd64.tar.gz | tar zxf - syft && mv syft /usr/bin/syft

WORKDIR /work

COPY ./rhtap ./rhtap/

# This is for the GitHub pipeline where currently we're not actually
# running in the container. Instead we copy the scripts and binaries
# from the image and run them directly. (This may change in future.)
COPY copy-scripts.sh /work/copy-scripts.sh
RUN chmod 755 /work/copy-scripts.sh

CMD ["/bin/bash"]
