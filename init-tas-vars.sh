# init tuf and REKOR

RT=$(oc get routes -n rhtap-tas -o name | grep rekor-server)
HOST=$(oc get -n rhtap-tas $RT -o jsonpath={.spec.host})
export MY_REKOR_HOST=https://$HOST


RT=$(oc get routes -n rhtap-tas -o name | grep tuf)
HOST=$(oc get -n rhtap-tas $RT -o jsonpath={.spec.host})
export MY_TUF_MIRROR=https://$HOST


echo "MY_REKOR_HOST set to $MY_REKOR_HOST"
echo "MY_TUF_MIRROR set to $MY_TUF_MIRROR"


