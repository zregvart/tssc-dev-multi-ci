# Disable built in rule for .sh files
MAKEFLAGS += -r

# A list of files that are built from templates
FILES=\
  Jenkinsfile \
  Jenkinsfile-local-shell-scripts \
  Jenkinsfile.gitops \
  Jenkinsfile.gitops-local-shell \
  .github/workflows/build-and-update-gitops.yml \
  rhtap.groovy \
  rhtap/build-pipeline-steps.sh \
  rhtap/promote-pipeline-steps.sh \
  \

# Node stuff
RENDER_DIR=./render/
RENDER_JS=render.cjs
RENDER=npx --prefix $(RENDER_DIR) node $(RENDER_DIR)/$(RENDER_JS)

# Force a rebuild
.PHONY: refresh
refresh: clean build

# Build
.PHONY: build
build: $(FILES)

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
	@npm --prefix $(RENDER_DIR) install --frozen-lockfile

#-----------------------------------------------------------------------------

.PHONY: push-images
push-images: push-image-gitlab

.PHONY: push-images
build-images: build-image-gitlab

# Todo: Find a proper home for these, and add unique tags
RUNNER_IMAGE_REPO=quay.io/$(USER)/rhtap-ci-images
TAG_PREFIX=rhtap-runner

.PHONY: push-image-%
push-image-%: build-image-%
	podman push $(RUNNER_IMAGE_REPO):$(TAG_PREFIX)-$*

.PHONY: build-image-%
build-image-%:
	podman build -f Dockerfile.$* -t $(RUNNER_IMAGE_REPO):$(TAG_PREFIX)-$*

.PHONY: run-image-%
run-image-%:
	podman run --rm -i -t $(RUNNER_IMAGE_REPO):$(TAG_PREFIX)-$*
