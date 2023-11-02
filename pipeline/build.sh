#!/bin/bash

APP_NAME=$1
BRANCH=$2
BRANCH_DEV=release

if [ ! -d "./dist/apps/${APP_NAME}" ];
    then echo "Skip deploy ${APP_NAME}";
    exit 0;
fi

mkdir version
touch version/${APP_NAME}.txt

 if [[ "${APP_NAME}" == "call-center-app" ]]; then
  export NX_APP_ID=$APP_ID_CALLCENTER
  export APP_ID=$APP_ID_CALLCENTER
fi

if [[ "${APP_NAME}" == "composer-app" ]]; then
  export NX_APP_ID=$APP_ID_COMPOSER
  export APP_ID=$APP_ID_COMPOSER
fi

if [[ "${APP_NAME}" == "survey-app" ]]; then
  export NX_APP_ID=$APP_ID_SURVEY
  export APP_ID=$APP_ID_SURVEY
fi

if [ "${BRANCH}" == "${BRANCH_DEV}" ]; then
    if [[ "${APP_NAME}" == *"-app" ]]; then
        export SURVEY_APP_MAP_API_KEY=$SURVEY_APP_MAP_API_KEY
        export SURVEY_ENDPOINT_API=$SURVEY_ENDPOINT_API_DEV
        export SURVEY_ENDPOINT_PUBLIC=$SURVEY_ENDPOINT_PUBLIC_DEV
        export NX_SERVICE=$SURVEY_ENDPOINT_API_DEV
        export NX_DOMAIN_COMPOSER_APP=$NX_DOMAIN_COMPOSER_APP_DEV
        export NX_DOMAIN_AUTH_APP=$NX_DOMAIN_AUTH_APP_DEV
        export NX_DOMAIN_SURVEY_APP=$SURVEY_ENDPOINT_PUBLIC_DEV
    fi
    cd apps/${APP_NAME}
    devspace run-pipeline pipeline
else
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    DOCKERFILE_PATH=./deployment/docker/Dockerfile;
    DOCKER_IMAGE_BASE=${AZURE_ACR_HOST}/${APP_NAME}
    DOCKER_IMAGE_PROD=$DOCKER_IMAGE_BASE:v1-build-${BITBUCKET_BUILD_NUMBER};
    DOCKER_IMAGE_STG=$DOCKER_IMAGE_BASE:v1-build-${BITBUCKET_BUILD_NUMBER}-beta;

    if [[ "${APP_NAME}" == *"-app" ]]; then
        DOCKERFILE_PATH=./deployment/docker/DockerfileWeb;

        if [[ "${APP_NAME}" == "auth-app" ]]; then
          DOCKERFILE_PATH=./deployment/docker/DockerfileStatic;
        fi

        if [[ "${APP_NAME}" == "call-center-app" ]]; then
          DOCKERFILE_PATH=./deployment/docker/DockerfileStatic;
          # export NX_APP_ID=$APP_ID_CALLCENTER
          # export APP_ID=$APP_ID_CALLCENTER
        fi

        # if [[ "${APP_NAME}" == "composer-app" ]]; then
        #   export NX_APP_ID=$APP_ID_COMPOSER
        #   export APP_ID=$APP_ID_COMPOSER
        # fi

        # if [[ "${APP_NAME}" == "survey-app" ]]; then
        #   export NX_APP_ID=$APP_ID_SURVEY
        #   export APP_ID=$APP_ID_SURVEY
        # fi

        DOCKER_IMAGE_PROD=$DOCKER_IMAGE_BASE:v1-build-${BITBUCKET_BUILD_NUMBER}-prod;
        export SURVEY_APP_MAP_API_KEY=$SURVEY_APP_MAP_API_KEY
        export SURVEY_ENDPOINT_API=$SURVEY_ENDPOINT_API_STAGING
        export SURVEY_ENDPOINT_PUBLIC=$SURVEY_ENDPOINT_PUBLIC_STAGING
        export NX_SERVICE=$SURVEY_ENDPOINT_API_STAGING
        export NX_DOMAIN_COMPOSER_APP=$NX_DOMAIN_COMPOSER_APP_STAGING
        export NX_DOMAIN_AUTH_APP=$NX_DOMAIN_AUTH_APP_STAGING
        export NX_DOMAIN_SURVEY_APP=$SURVEY_ENDPOINT_PUBLIC_STAGING
        yarn build --prod ${APP_NAME} --skip-nx-cache

        echo "building beta image..."
        docker build \
            -t ${DOCKER_IMAGE_STG} \
            . \
            --build-arg APP_BUILD=${APP_NAME} \
            -f ${DOCKERFILE_PATH}

        export SURVEY_APP_MAP_API_KEY=$SURVEY_APP_MAP_API_KEY
        export SURVEY_ENDPOINT_API=$SURVEY_ENDPOINT_API_PRODUCTION
        export SURVEY_ENDPOINT_PUBLIC=$SURVEY_ENDPOINT_PUBLIC_PRODUCTION
        export NX_SERVICE=$SURVEY_ENDPOINT_API_PRODUCTION
        export NX_DOMAIN_COMPOSER_APP=$NX_DOMAIN_COMPOSER_APP_PRODUCTION
        export NX_DOMAIN_AUTH_APP=$NX_DOMAIN_AUTH_APP_PRODUCTION
        export NX_DOMAIN_SURVEY_APP=$SURVEY_ENDPOINT_PUBLIC_PRODUCTION
        yarn build --prod ${APP_NAME} --skip-nx-cache
    fi

    echo "building prod image...."
    docker build \
        -t ${DOCKER_IMAGE_PROD} \
        . \
        --build-arg APP_BUILD=${APP_NAME} \
        -f ${DOCKERFILE_PATH}

    docker login $AZURE_ACR_HOST -u $AZURE_ACR_USERNAME -p $AZURE_ACR_PASSWORD

    echo "pushing prod image..."
    docker push ${DOCKER_IMAGE_PROD}
    echo  ${DOCKER_IMAGE_PROD} >> version/${APP_NAME}.txt

    if [[ "${APP_NAME}" == *"-app" ]]; then
        echo "pushing beta image..."
        docker push ${DOCKER_IMAGE_STG}
        echo  ${DOCKER_IMAGE_STG} >> version/${APP_NAME}.txt
    fi
fi
