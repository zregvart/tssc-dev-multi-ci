
# get local test repos to patch
source setup-local-dev-repos.sh

if [ $TEST_REPO_ORG == "redhat-appstudio" ]; then
    echo "Cannot do CI testing using the redhat-appstudio org"
    echo "You must create forks in your own org and set up MY_TEST_REPO_ORG (github) and MY_TEST_REPO_GITLAB_ORG"
    exit
fi

function  updateGitAndQuayRefs() { 
    sed -i "s!quay.io/redhat-appstudio!quay.io/$MY_QUAY_USER!g" $1
    sed -i "s!https://github.com/redhat-appstudio!https://github.com/$MY_GITHUB_USER!g" $1 
}
#Jenkins 
echo "Update Jenkins file in $BUILD and $GITOPS" 
echo "Jenkins to reuse the Github repo" 
cp Jenkinsfile $BUILD/Jenkinsfile   
cp Jenkinsfile.gitops $GITOPS/Jenkinsfile
updateGitAndQuayRefs $BUILD/Jenkinsfile
updateGitAndQuayRefs $GITOPS/Jenkinsfile
# ENV with params

function updateBuild() { 
    REPO=$1
    GITOPS_REPO_UPDATE=$2
    mkdir -p $REPO/rhtap
    SETUP_ENV=$REPO/rhtap/env.sh
    cp rhtap/env.template.sh $SETUP_ENV 
    sed -i "s!\${{ values.image }}!quay.io/$MY_QUAY_USER/bootstrap!g" $SETUP_ENV
    sed -i "s!\${{ values.dockerfile }}!Dockerfile!g" $SETUP_ENV
    sed -i "s!\${{ values.buildContext }}!.!g" $SETUP_ENV
    sed -i "s!\${{ values.repoURL }}!$GITOPS_REPO_UPDATE!g" $SETUP_ENV
    # Set MY_REKOR_HOST and MY_TUF_MIRROR to 'none' if these services are not available
    sed -i 's!export REKOR_HOST=.*$!export REKOR_HOST="\${MY_REKOR_HOST:-http://rekor-server.rhtap.svc}"!' $SETUP_ENV
    sed -i 's!export TUF_MIRROR=.*$!export TUF_MIRROR="\${MY_TUF_MIRROR:-http://tuf.rhtap.svc}"!' $SETUP_ENV
    echo "# Update forced CI test $(date)" >>$SETUP_ENV
    updateGitAndQuayRefs $SETUP_ENV
    cat $SETUP_ENV
}
# Repos on github and gitlab, github reused for Jenkins
# source repos get the name of the corresponding GITOPS REPO
updateBuild $BUILD $TEST_GITOPS_REPO
updateBuild $GITOPS  
updateBuild $GITLAB_BUILD $TEST_GITOPS_GITLAB_REPO
updateBuild $GITLAB_GITOPS 

# Gitlab CI  
echo "Update .gitlab-ci.yml file in $BUILD and $GITOPS" 
cp .gitlab-ci.yml $GITLAB_BUILD/.gitlab-ci.yml
cp .gitlab-ci.gitops.yml $GITLAB_GITOPS/.gitlab-ci.yml

updateGitAndQuayRefs $GITLAB_BUILD/.gitlab-ci.yml
updateGitAndQuayRefs $GITLAB_GITOPS/.gitlab-ci.yml

# Github Actions  
echo "Update .github workflows in $BUILD and $GITOPS"  
echo "WARNING No  .github workflows in $GITOPS"  
cp -r .github $BUILD  
# add  $GITOPS/.github/workflows/* when workflow exists
for wf in $BUILD/.github/workflows/*
do
    echo "Fix WF $wf"
    sed -i 's/workflow_dispatch/push, workflow_dispatch/g'  $wf
    updateGitAndQuayRefs $wf
    echo "-"
done

function updateRepos() {
    REPO=$1  
    echo 
    echo "Updating $REPO" 
    pushd $REPO
    git add . 
    git commit -m "Testing in CI"  
    git push   
    popd
}

# github 
updateRepos $BUILD      
updateRepos $GITOPS  
# gitlab
updateRepos $GITLAB_BUILD    
updateRepos $GITLAB_GITOPS   

bash hack/ghub-set-vars $TEST_BUILD_REPO 
bash hack/ghub-set-vars $TEST_GITOPS_REPO  
bash hack/glab-set-vars $(basename $TEST_BUILD_GITLAB_REPO) 
bash hack/glab-set-vars $(basename $TEST_GITOPS_GITLAB_REPO)   

echo "Github Build and Gitops Repos" 
echo "Build: $TEST_BUILD_REPO"
echo "Gitops: $TEST_GITOPS_REPO" 

echo "Gitlab Build and Gitops Repos" 
echo "Build: $TEST_BUILD_GITLAB_REPO"
echo "Gitops: $TEST_GITOPS_GITLAB_REPO" 


