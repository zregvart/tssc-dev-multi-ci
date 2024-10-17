# Disable built in rule for .sh files
MAKEFLAGS += -r

# A list of files that are built from templates
FILES=\
  Jenkinsfile \
  Jenkinsfile-local-shell-scripts \
  Jenkinsfile.gitops \
  Jenkinsfile.gitops-local-shell \
  .github/workflows/build-and-update-gitops.yml \
  .gitlab-ci.yml \
  .gitlab-ci.gitops.yml \
  rhtap.groovy \
  rhtap/build-pipeline-steps.sh \
  rhtap/promote-pipeline-steps.sh \
  \

RENDER=node ./render/render.cjs

# Build
.PHONY: build
build: $(FILES)

# Force a rebuild
.PHONY: refresh
refresh: clean build

define build_recipe
	@echo "Building $@"
	@mkdir -p $$(dirname $@)
	@$(RENDER) $< templates/data.yaml targetFile=$@ templateFile=$< > $@
endef

# Generate one file from its template
# (Need multiple patterns because % won't match a / char)
%: templates/%.njk
	$(build_recipe)

rhtap/%: templates/%.njk
	$(build_recipe)

.github/workflows/%: templates/%.njk
	$(build_recipe)

# This should produce a non-zero exit code if there are
# generated files that are not in sync with the templates
.PHONY: ensure-fresh
ensure-fresh:
	@$(MAKE) refresh > /dev/null && git diff --exit-code -- $(FILES)

# Remove generated files
.PHONY: clean
clean:
	@rm -f $(FILES)

# Install required node modules
.PHONY: install-deps
install-deps:
	@npm --prefix ./render install --frozen-lockfile

#-----------------------------------------------------------------------------

.PHONY: push-images
push-images: push-image-gitlab push-image-github
	@echo https://quay.io/repository/redhat-appstudio/dance-bootstrap-app?tab=tags

.PHONY: build-images
build-images: build-image-gitlab build-image-github

RUNNER_IMAGE_REPO=quay.io/redhat-appstudio/dance-bootstrap-app
TAG_PREFIX=rhtap-runner

define floating-tag
	$(RUNNER_IMAGE_REPO):$(TAG_PREFIX)-$*
endef

define unique-tag
	$(RUNNER_IMAGE_REPO):$(TAG_PREFIX)-$*-$$(git rev-parse --short HEAD)
endef

# Todo: Check for uncommited changes before pushing
.PHONY: push-image-%
push-image-%: build-image-%
	podman push $(floating-tag)
	podman push $(unique-tag)

.PHONY: build-image-%
build-image-%:
	podman build -f Dockerfile.$* -t $(floating-tag)
	podman tag $(floating-tag) $(unique-tag)

.PHONY: run-image-%
run-image-%:
	podman run --rm -i -t $(floating-tag)
