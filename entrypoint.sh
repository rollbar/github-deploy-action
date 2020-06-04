#!/bin/bash

# Ensure that the ROLLBAR_ACCESS_TOKEN secret is included
if [[ -z "$ROLLBAR_ACCESS_TOKEN" ]]; then
  echo "Set the ROLLBAR_ACCESS_TOKEN env variable."
  exit 1
fi

# Ensure that the environment is included
if [[ -z "$1" ]]; then
  echo "Missing the environment argument."
  exit 1
fi

# Ensure that the version is included
if [[ -z "$2" ]]; then
  echo "Missing the version argument."
  exit 1
fi

# If DEPLOY_ID is present it's a deploy update
if [[ -z "$DEPLOY_ID" ]]; then
    METHOD="POST"
else
    METHOD="PATCH"
fi

RESPONSE=$(curl -X $METHOD https://api.rollbar.com/api/1/deploy/$DEPLOY_ID \
                -H "X-ROLLBAR-ACCESS-TOKEN: $ROLLBAR_ACCESS_TOKEN" \
                --form environment=$1 \
                --form revision=$2 \
                --form status=$3 \
                --form rollbar_username=$ROLLBAR_USERNAME)

# Get the deploy id depending on the response as they are different for POST and PATCH
if [[ $METHOD == "POST" ]]; then
    ROLLBAR_DEPLOY_ID=$(echo $RESPONSE | jq -r '.data.deploy_id')
else
    ROLLBAR_DEPLOY_ID=$(echo $RESPONSE | jq -r '.result.id')
fi

# If not ROLLBAR_DEPLOY_ID something failed
if [[ "$ROLLBAR_DEPLOY_ID" == "null" ]]; then
    exit 1
fi

# Done
echo "::set-output name=deploy_id::$ROLLBAR_DEPLOY_ID"

# Source map is provided
if [[ "$4" ]]; then
    echo "Uploading source map..."
    RESPONSE_SOURCE_MAP=$(curl -v https://api.rollbar.com/api/1/sourcemap \
                          -F access_token=$ROLLBAR_ACCESS_TOKEN \
                          -F version=$2 \
                          -F minified_url=$5 \
                          -F source_map=@$4)
fi
                          
