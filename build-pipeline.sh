

# Fill in template values and set run local
# the env.template is copyed to the RHDH sample templates
# into env.sh and is filled in by the template expansion
export LOCAL_SHELL_RUN=true
SETUP_ENV=rhtap/env.sh 
cp rhtap/env.template.sh $SETUP_ENV
sed -i "s!\${{ values.image }}!quay.io/jduimovich0/bootstrap!g" $SETUP_ENV
sed -i "s!\${{ values.dockerfile }}!Dockerfile!g" $SETUP_ENV
sed -i "s!\${{ values.buildContext }}!.!g" $SETUP_ENV
sed -i "s!\${{ values.repoURL }}! !g" $SETUP_ENV
source $SETUP_ENV
cat $SETUP_ENV

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
