#!/bin/bash

APP_NAME=krakend-service
BRANCH=$1
BRANCH_DEV=release

if [ "${BRANCH}" != "${BRANCH_DEV}" ]; then
    echo "Skip build ${APP_NAME}";
    exit 0;
fi

mkdir version
touch version/${APP_NAME}.txt

cd deployment/krakend

export DOCKER_DEFAULT_PLATFORM=linux/amd64
DOCKER_IMAGE_BASE=${AZURE_ACR_HOST}/${APP_NAME}
DOCKER_IMAGE=$DOCKER_IMAGE_BASE:v1-build-$BITBUCKET_BUILD_NUMBER;

echo "building image..."
docker build  -t ${DOCKER_IMAGE} .

echo "pushing image..."
docker login $AZURE_ACR_HOST -u $AZURE_ACR_USERNAME -p $AZURE_ACR_PASSWORD
docker push ${DOCKER_IMAGE}
echo  ${DOCKER_IMAGE} >> ../../version/${APP_NAME}.txt