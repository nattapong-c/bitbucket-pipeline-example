#!/bin/bash

APP_NAME=$1
BRANCH=$2
BRANCH_DEV=release

if [ ! -d "./dist/apps/${APP_NAME}" ] && [ "${APP_NAME}" != "krakend-service" ]; 
    then echo "Skip deploy ${APP_NAME}";
    exit 0;
fi

curl -sL https://aka.ms/InstallAzureCLIDeb | bash
az login --service-principal --username $AZURE_APP_ID --password $AZURE_PASSWORD --tenant $AZURE_TENANT_ID

if [ "${APP_NAME}" == "krakend-service" ]; then
    echo "Skip install package ${APP_NAME}";
    exit 0;
fi

if [ "${BRANCH}" == "${BRANCH_DEV}" ]; then
    az aks get-credentials -n $AKS_NAME -g $AZURE_RESOURCE_GROUP

    curl -L -o devspace "https://github.com/loft-sh/devspace/releases/latest/download/devspace-linux-amd64" && install -c -m 0755 devspace /usr/local/bin
    devspace use namespace $AKS_NAMESPACE
fi