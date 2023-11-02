#!/bin/bash

BRANCH=$1

TITLE=""

if [ -d version ]; then
    ls -al version
    if [ ! -z "$(ls -A version)" ]; then
        TITLE="Devspace"
        for FILE in version/*.txt; do 
            NAME=$(echo $FILE | sed -e "s/version\///g" | sed -e "s/.txt//g")
            VERSION=$(awk '{printf "%s\\n", $0}' $FILE);
            if [ "${VERSION}" != "" ]; then
                TITLE="Images"
                MSG+=$VERSION
            else
                MSG+=${NAME}"\n"
            fi
        done
    fi
fi

if [ "${MSG}" == "" ]; then
    TITLE="No-images-build"
fi

echo "sending notification..."
curl --location ${WEBHOOK_DISCORD} \
            --header "Content-Type: application/json" \
            --data '{
                "content": "Pipeline done\n\n'${TITLE}'\n\n'${MSG}'",
                "embeds": [
                    {
                        "title": "branch: '${BRANCH}'",
                        "color": 5763719
                    }
                ]
            }'