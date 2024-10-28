
for git in  gitlab github
do
    IMG=quay.io/$MY_QUAY_USER/dance-bootstrap-app:rhtap-runner-$git
    echo "Building and pushing $IMG"
    docker buildx build . -f Dockerfile.$git -t $IMG
    docker push $IMG
done
