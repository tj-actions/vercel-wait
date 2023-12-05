#!/usr/bin/env bash

set -exuo pipefail

start_time=$(date +%s)

deployment_ready=false

request_url="https://api.vercel.com/v6/deployments?projectId=$INPUT_PROJECT_ID&limit=100"

if [[ -n "$INPUT_TEAM_ID" ]]; then
  request_url="$request_url&teamId=$INPUT_TEAM_ID"
fi

echo "::debug::Retrieving Deployments from: $request_url"

while [ "$deployment_ready" = false ] && [ "$(($(date +%s) - start_time))" -lt "$INPUT_TIMEOUT" ]; do
  echo "::debug::Requesting deployments from: $request_url"
  response=$(curl -s "$request_url" -H "Authorization: Bearer $INPUT_TOKEN") && exit_status=$? || exit_status=$?
  
  if [[ $exit_status -ne 0 ]]; then
    echo "::warning::Failed to get deployment from: $request_url"
    break
  fi
  
  echo "::debug::Parsing the response from: $request_url"
  
  deployment=$(echo "$response" | jq -r --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA)')
  
  id=$(echo "$deployment" | jq -r '.uid')
  url=$(echo "$deployment" | jq -r '.url')
  state=$(echo "$deployment" | jq -r '.state')
  alias_error=$(echo "$deployment" | jq -r '.aliasError')

  if [ "$state" = "READY" ]; then
    deployment_ready=true
    cat <<EOF >>"$GITHUB_OUTPUT"
id=$id
url=$url
state=$state
alias_error=$alias_error
EOF
    break
  fi

  next=$(echo "$response" | jq -r '.pagination.next')

  if [ "$next" != "null" ]; then
    if [[ $request_url == *"until"* ]]; then
      # If "until" parameter already exists, replace it
      request_url=$(echo $request_url | sed "s/until=[0-9]*/until=$next/")
    else
      # If "until" parameter does not exist, add it
      request_url="$request_url&until=$next"
    fi
  else
    break
  fi
done

if [ "$deployment_ready" = false ]; then
  echo "::error::Deployment did not become ready within the specified timeout of: $INPUT_TIMEOUT seconds"
  exit 1
fi
