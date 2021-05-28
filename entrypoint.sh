#!/bin/bash

ENVIRONMENT=$1
VERSION=$2
STATUS=$3
SOURCE_MAP_FILES=$4
MINIFIED_FILES=$5
LOCAL_USERNAME=$6
COMMENT=$7

# Ensure that the ROLLBAR_ACCESS_TOKEN secret is included
if [[ -z "$ROLLBAR_ACCESS_TOKEN" ]]; then
  echo "Set the ROLLBAR_ACCESS_TOKEN env variable."
  exit 1
fi

# Ensure that the environment is included
if [[ -z "$ENVIRONMENT" ]]; then
  echo "Missing the environment argument."
  exit 1
fi

# Ensure that the version is included
if [[ -z "$VERSION" ]]; then
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
                --form environment=$ENVIRONMENT \
                --form revision=$VERSION \
                --form status=$STATUS \
                --form rollbar_username=$ROLLBAR_USERNAME \
                --form local_username=$LOCAL_USERNAME) \
                --form comment=$COMMENT)

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
if [[ "$SOURCE_MAP_FILES" ]]; then
    echo "Uploading source map..."
    map_files_array=($SOURCE_MAP_FILES)
    min_files_array=($MINIFIED_FILES)
    if [[ "${#map_files_array[@]}" -ne "${#min_files_array[@]}" ]]; then
        echo "Number of source map files and minified files are not equal."
        exit 1
    fi
    for i in ${!map_files_array[@]}; do
        echo "${map_files_array[$i]} : ${min_files_array[$i]}"
        curl -v https://api.rollbar.com/api/1/sourcemap \
                      -F access_token=$ROLLBAR_ACCESS_TOKEN \
                      -F version=$2 \
                      -F minified_url=${min_files_array[$i]} \
                      -F source_map=@${map_files_array[$i]}
    done
fi

