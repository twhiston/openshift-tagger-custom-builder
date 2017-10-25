#!/bin/bash

# This script :
# - retrieves an id from a specified label
# - tag this image with the id

set -e # fail fast
set -o pipefail
IFS=$'\n\t'

if [ "$DEBUG_VERBOSE" = true ]; then
    set -x # debug
    env | sort
fi

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi

if [ -z "$BUILD_NAMESPACE" ]; then
    BUILD_NAMESPACE=$(eval cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
fi
if [ -z "$OUTPUT_NAMESPACE" ]; then
    OUTPUT_NAMESPACE="$BUILD_NAMESPACE"
fi
if [ -z "$OUTPUT_IMAGE" ]; then
    OUTPUT_IMAGE="$BUILD_IMAGE"
fi

if [ -z "$TAG_LABEL" ]; then
    TAG_LABEL="io.openshift.build.image-tagger"
fi

if [ -z "$PUSH_IMAGE" ]; then
    PUSH_IMAGE="true"
fi

if [ -z "$TOKEN" ]; then
  echo "Using service account token"
  TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
fi

if [ "$DEBUG" = true ]; then
    echo "Build Namespace: ${BUILD_NAMESPACE}"
    echo "Build Image: ${BUILD_IMAGE}"
    echo "Output Namespace: ${OUTPUT_NAMESPACE}"
    echo "Output Image: ${OUTPUT_IMAGE}"
    echo "Docker Socket: ${DOCKER_SOCKET}"
    echo "Tag Label: ${TAG_LABEL}"
    echo "Push Image: ${PUSH_IMAGE}"
fi

oc login https://$KUBERNETES_PORT_443_TCP_ADDR:$KUBERNETES_SERVICE_PORT_HTTPS \
  --token "${TOKEN}" \
  --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

COMMIT_ID=$(oc get istag $BUILD_IMAGE:latest -o json -n $BUILD_NAMESPACE | jq -r ".image.dockerImageMetadata.Config.Labels.\"io.openshift.build.commit.id\"")
oc tag $BUILD_IMAGE:latest $OUTPUT_IMAGE:$COMMIT_ID -n $BUILD_NAMESPACE


if [[ -d "$PUSH_DOCKERCFG_PATH" ]] && [[ ! -e ~/.docker ]]; then
    if [ "$DEBUG" = true ]; then
        echo "Using push secret"
    fi
    mkdir ~/.docker
    cp "$PUSH_DOCKERCFG_PATH"/.dockerconfigjson ~/.docker/config.json
fi


if [ "$PUSH_IMAGE" = true ] ; then
    REAL_NAME=$(oc get imagestream drupal-module-tester -o json | jq -r ".status.dockerImageRepository")
    BUILD_TAG=$(oc get istag $BUILD_IMAGE:latest -o json -n $BUILD_NAMESPACE | jq -r ".image.dockerImageMetadata.Config.Labels.\"${TAG_LABEL}\"")
    BUILD_TAG=$(echo $BUILD_TAG | sed 's/[^a-zA-Z0-9\_\-]//g')
    REAL_OUTPUT="$OUTPUT_NAMESPACE/$OUTPUT_IMAGE:$BUILD_TAG"

    if [ "$DEBUG" = true ]; then
        echo "Pushing Image"
        echo "Docker Socket: ${DOCKER_SOCKET}"
        echo "Full push id: $REAL_OUTPUT"
    fi

    docker tag $REAL_NAME $REAL_OUTPUT
    docker push "$REAL_OUTPUT"
    if [ "$PUSH_CLEANUP" = true ] ; then
        docker rmi "$REAL_OUTPUT"
    fi
fi

