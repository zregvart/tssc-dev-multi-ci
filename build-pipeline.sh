

# Fill in template values and set run local
# the env.template is copyed to the RHDH sample templates
# into env.sh and is filled in by the template expansion
export LOCAL_SHELL_RUN=true

# optional set repo url and it will update this repo with the new image
# this means you need to pull after a build to be in sync

# get the URL of the repo, works for forks 
OPTIONAL_REPO_UPDATE=$(git remote get-url origin)   
# don't image gitops, good for testing build only	
OPTIONAL_REPO_UPDATE=   	

REQUIRED_ENV="MY_QUAY_USER "
REQUIRED_BINARY="tree "
rhtap/verify-deps-exist "$REQUIRED_ENV" "$REQUIRED_BINARY" 

SETUP_ENV=rhtap/env.sh 
cp rhtap/env.template.sh $SETUP_ENV
sed -i "s!\${{ values.image }}!quay.io/$MY_QUAY_USER/bootstrap!g" $SETUP_ENV
sed -i "s!\${{ values.dockerfile }}!Dockerfile!g" $SETUP_ENV
sed -i "s!\${{ values.buildContext }}!.!g" $SETUP_ENV
sed -i "s!\${{ values.repoURL }}!$OPTIONAL_REPO_UPDATE!g" $SETUP_ENV
source $SETUP_ENV 

COUNT=0

function run () { 
    let "COUNT++"
    printf "\n"
    printf '=%.0s' {1..31}
    printf " %d " $COUNT
    printf '=%.0s' {1..32}
    bash $1
    ERR=$?
    echo "Error code for $1 = $ERR"
    printf '_%.0s' {1..64}
    printf "\n" 
    if [ $ERR != 0 ]; then
        echo "Fatal Error code for $1 = $ERR" 
        exit 1
    fi
}
rm -rf ./results

run  "rhtap/init.sh"  
run  "rhtap/buildah-rhtap.sh"  
run  "rhtap/acs-deploy-check.sh"  
run  "rhtap/acs-image-check.sh"  
run  "rhtap/acs-image-scan.sh"  
run  "rhtap/update-deployment.sh"  
run  "rhtap/show-sbom-rhdh.sh"  
run  "rhtap/summary.sh"  

tree ./results 
