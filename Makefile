# Disable built in rule for .sh files
MAKEFLAGS += -r

# A list of files that are built from templates
FILES=\
  generated/source-repo/jenkins/Jenkinsfile \
  generated/source-repo/githubactions/.github/workflows/build-and-update-gitops.yml \
  generated/source-repo/gitlabci/.gitlab-ci.yml \
  \
  generated/gitops-template/jenkins/Jenkinsfile \
  generated/gitops-template/githubactions/.github/workflows/gitops-promotion.yml \
  generated/gitops-template/gitlabci/.gitlab-ci.yml \
  \
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

# Shared build recipe for generated a file from a template
define build_recipe
	@echo "Building $@"
	@mkdir -p $$(dirname $@)
	@$(RENDER) $< templates/data.yaml targetFile=$@ templateFile=$< > $@
endef

# Reduce repetition in this file by creating a template
TARGET_DIRS=\
  jenkins \
  githubactions/.github/workflows \
  gitlabci

define targets_for_ci_type
generated/source-repo/$(1)/%: templates/source-repo/%.njk
	$$(build_recipe)

generated/gitops-template/$(1)/%: templates/gitops-template/%.njk
	$$(build_recipe)

endef

# Create the targets each CI type
$(foreach target_dir,$(TARGET_DIRS),$(eval $(call targets_for_ci_type,$(target_dir))))

# For the two pipeline-steps.sh files
rhtap/%: templates/%.njk
	$(build_recipe)

# For rhtap.groovy
%: templates/%.njk
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

# Let's not push the common base image
.PHONY: push-images
push-images: push-image-gitlab push-image-github
	@echo https://quay.io/repository/redhat-appstudio/dance-bootstrap-app?tab=tags

.PHONY: build-images
build-images: build-image-base build-image-gitlab build-image-github

RUNNER_IMAGE_REPO=quay.io/redhat-appstudio/dance-bootstrap-app
#RUNNER_IMAGE_REPO=quay.io/$(USER)/dance-bootstrap-app
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
