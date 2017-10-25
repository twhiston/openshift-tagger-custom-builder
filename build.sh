#!/bin/bash
set -o pipefail
IFS=$'\n\t'

DOCKER_SOCKET=/var/run/docker.sock

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi

if [ -n "${OUTPUT_IMAGE}" ]; then
    if [ -n "${OUTPUT_REGISTRY}" ]; then
        TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
    else
        TAG="${OUTPUT_IMAGE}"
    fi
fi

if [[ "${SOURCE_REPOSITORY}" != "git://"* ]] && [[ "${SOURCE_REPOSITORY}" != "git@"* ]]; then
  URL="${SOURCE_REPOSITORY}"
  if [[ "${URL}" != "http://"* ]] && [[ "${URL}" != "https://"* ]]; then
    URL="https://${URL}"
  fi
  curl --head --silent --fail --location --max-time 16 $URL > /dev/null
  if [ $? != 0 ]; then
    echo "Could not access source url: ${SOURCE_REPOSITORY}"
    exit 1
  fi
fi

if [ -n "${SOURCE_REF}" ]; then
  BUILD_DIR=$(mktemp --directory)
  git clone --recursive "${SOURCE_REPOSITORY}" "${BUILD_DIR}"
  if [ $? != 0 ]; then
    echo "Error trying to fetch git source: ${SOURCE_REPOSITORY}"
    exit 1
  fi
  pushd "${BUILD_DIR}"
  git checkout "${SOURCE_REF}"
  if [ $? != 0 ]; then
    echo "Error trying to checkout branch: ${SOURCE_REF}"
    exit 1
  fi
  popd
  docker build --rm -t "${TAG}" "${BUILD_DIR}"
else
  docker build --rm -t "${TAG}" "${SOURCE_REPOSITORY}"
fi

cp -R ${PUSH_DOCKERCFG_PATH}/ /root/.dockercfg/
ls -la /root/.dockercfg/
cat /root/.dockercfg/config.json

if [ -n "${OUTPUT_IMAGE}" ] || [ -s "/root/.dockercfg" ]; then
  docker push "${TAG}"
  if [ -n "${BUILD_TAG}" ]; then
    BUILDTAG="${TAG}:${BUILD_TAG}"
    echo "Retagging image as ${BUILDTAG}"
    docker tag "${TAG}" "${BUILD_TAG}"
    docker push "${BUILD_TAG}"
#   docker rmi "${BUILD_TAG}"
  fi
fi