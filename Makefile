
# A list of files that are built from templates
FILES=\
  Jenkinsfile \
  Jenkinsfile-local-shell-scripts \
  Jenkinsfile.gitops \
  Jenkinsfile.gitops-local-shell

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

# Generate one file from its template
%: templates/%.njk
	@echo "Building $@"
	@mkdir -p $$(dirname $@)
	@$(RENDER) $< templates/data.yaml targetFile=$@ templateFile=$< > $@

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
