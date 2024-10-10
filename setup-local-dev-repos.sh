echo "Configure the repos for Innerloop dev"
echo "Build can use a repo directly, gitops needs a forked repo."
echo "Set MY_TEST_REPO_ORG to test your forks of the repos"

TEST_REPO_ORG="${MY_TEST_REPO_ORG:-redhat-appstudio}"

# this will be copied into a temp directory
# pipelines will be pushed into it for local test
TEST_BUILD_REPO=https://github.com/$TEST_REPO_ORG/devfile-sample-nodejs-dance

# This should be optional, if it doesn't exist
# the build can continue
TEST_GITOPS_REPO=https://github.com/$TEST_REPO_ORG/tssc-dev-gitops

BUILD_EXISTS=$(curl -s -o /dev/null -I -w "%{http_code}" $TEST_BUILD_REPO)
GITOPS_EXISTS=$(curl -s -o /dev/null -I -w "%{http_code}" $TEST_GITOPS_REPO)
# 200 == exists
# 404 == no exists

# clone if repos exist, disable gitops
BUILD=tmp/build
GITOPS=tmp/gitops
rm -rf $BUILD
rm -rf $GITOPS

echo "Build Configuration: "
if [ $BUILD_EXISTS == 200 ]; then
  echo "Source: $TEST_BUILD_REPO"
  echo "Local Source directory: $BUILD"
  git clone --quiet $TEST_BUILD_REPO $BUILD > /dev/null
else
  echo "Cannot find build tets repo $TEST_BUILD_REPO"
fi
if [ $GITOPS_EXISTS == 200 ]; then
  echo "Gitops: $TEST_GITOPS_REPO"
  echo "Local Gitops directory: $GITOPS"
  git clone --quiet $TEST_GITOPS_REPO $GITOPS  > /dev/null
else
  echo "Cannot use gitops repo $TEST_GITOPS_REPO"
  echo "****************"
  echo "Build will continue, but Gitops update will be disabled"
  echo "****************"
  TEST_GITOPS_REPO=""
fi

# WARNING - if GITOPS_REPO_URL is set, the update deployment will try to update
# the gitops repo. Disable this here if the gitops repo is NOT
if [ $TEST_REPO_ORG == "redhat-appstudio" ]; then
  echo "------------- INFO-------------"
  echo "DISABLING GITOPS REPO UPDATE for the "redhat-appstudio" org"
  echo "This prevents random accidental updates to the shared repo by dev team members with access"
  export DISABLE_GITOPS_UPDATE=true
  echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
  echo
fi

