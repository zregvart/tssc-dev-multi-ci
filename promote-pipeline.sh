

# Fill in template values and set run local
# the env.template is copyed to the RHDH sample templates
# into env.sh and is filled in by the template expansion
export LOCAL_SHELL_RUN=true

REQUIRED_ENV="MY_QUAY_USER "
REQUIRED_BINARY="tree "
rhtap/verify-deps-exist "$REQUIRED_ENV" "$REQUIRED_BINARY" 
ERR=$?
echo "Dependency Error $1 = $ERR" 
if [ $ERR != 0 ]; then
	echo "Fatal Error code for $1 = $ERR" 
	exit $ERR
fi


SETUP_ENV=rhtap/env.sh 
cp rhtap/env.template.sh $SETUP_ENV
sed -i "s!\${{ values.image }}!quay.io/\${MY_QUAY_USER:-jduimovich0}/bootstrap!g" $SETUP_ENV
sed -i "s!\${{ values.dockerfile }}!Dockerfile!g" $SETUP_ENV
sed -i "s!\${{ values.buildContext }}!.!g" $SETUP_ENV
sed -i "s!\${{ values.repoURL }}!!g" $SETUP_ENV

# Set MY_REKOR_HOST and MY_TUF_MIRROR to 'none' if these services are not available
sed -i 's!export REKOR_HOST=.*$!export REKOR_HOST="\${MY_REKOR_HOST:-http://rekor-server.rhtap.svc}"!' $SETUP_ENV
sed -i 's!export TUF_MIRROR=.*$!export TUF_MIRROR="\${MY_TUF_MIRROR:-http://tuf.rhtap.svc}"!' $SETUP_ENV

source $SETUP_ENV
cat $SETUP_ENV
# When running in Jenkins the secret values will be read from credentials
# Todo: We need to restrict access to the signing secret. Here we need only
# the public key, the rest of the secret should not be visible at all.
SIGNING_SECRET_ENV=rhtap/signing-secret-env.sh
source $SIGNING_SECRET_ENV

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
run  "rhtap/gather-deploy-images.sh"  
run  "rhtap/verify-enterprise-contract.sh"   

tree ./results 
