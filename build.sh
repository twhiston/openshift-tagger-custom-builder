#!/bin/bash

# This script :
# - retrieves an id from a specified label
# - tag this image with the id

set -e # fail fast
set -o pipefail
IFS=$'\n\t'


if [[ -v $DEBUG ]]; then
    set -x # debug
    env | sort
fi

if [ -z "$BUILD_NAMESPACE" ]; then
    BUILD_NAMESPACE=$(eval cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
fi

echo "Build Namespace: ${BUILD_NAMESPACE}"
echo "Build Image: ${BUILD_IMAGE}"


if [ -z "$TOKEN" ]; then
  TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
fi

oc login https://$KUBERNETES_PORT_443_TCP_ADDR:$KUBERNETES_SERVICE_PORT_HTTPS \
  --token `cat /var/run/secrets/kubernetes.io/serviceaccount/token` \
  --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

COMMIT_ID=$(oc get istag $BUILD_IMAGE:latest -o json -n $BUILD_NAMESPACE | jq -r ".image.dockerImageMetadata.Config.Labels.\"io.openshift.build.commit.id\"")
oc tag $BUILD_IMAGE:latest $BUILD_IMAGE:$COMMIT_ID -n $BUILD_NAMESPACE


if [ "${PUSH_IMAGE}" = true ] ; then
    docker push $BUILD_IMAGE:$COMMIT_ID
fi

