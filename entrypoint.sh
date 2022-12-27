#!/usr/bin/env bash

set -euo pipefail

start_time=$(date +%s)

deployment_ready=false

url="https://api.vercel.com/v6/deployments?projectId=$INPUT_PROJECT_ID&limit=100"

if [[ -n "$INPUT_TEAM_ID" ]]; then
  url="$url&teamId=$INPUT_TEAM_ID"
fi

echo "::debug::Retrieving Deployments from: $url"

while [ "$deployment_ready" = false ] && [ "$(($(date +%s) - start_time))" -lt "$INPUT_TIMEOUT" ]; do
  echo "::debug::Requesting deployments from: $url"
  response=$(curl -s "$url" -H "Authorization: Bearer $INPUT_TOKEN" | jq -r --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA)') && exit_status=$? || exit_status=$?
  
  if [[ $exit_status -ne 0 ]]; then
    echo "::warning::Failed to get deployment from: $url"
  fi

  echo "::debug::Parsing the response from: $url"

  id=$(jq -r '.uid' <<< "$response")
  url=$(jq -r '.url' <<< "$response")
  state=$(jq -r '.state' <<< "$response")
  alias_error=$(jq -r '.aliasError' <<< "$response")

  if [ "$state" = "READY" ]; then
    deployment_ready=true
    cat <<EOF >>"$GITHUB_OUTPUT"
id=$id
url=$url
state=$state
alias_error=$alias_error
EOF
  fi

  echo "::debug::Unable to retrieve deployment sleeping for: $INPUT_DELAY seconds"

  sleep "$INPUT_DELAY"
done

if [ "$deployment_ready" = false ]; then
  echo "::error::Deployment did not become ready within the specified timeout of: $INPUT_TIMEOUT seconds"
  exit 1
fi
