

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
