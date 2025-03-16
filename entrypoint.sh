#!/usr/bin/env bash

set -euo pipefail

start_time=$(date +%s)
deployment_ready=false
base_request_url="https://api.vercel.com/v6/deployments?projectId=$INPUT_PROJECT_ID&limit=100"

if [[ -n "$INPUT_TEAM_ID" ]]; then
  base_request_url="$base_request_url&teamId=$INPUT_TEAM_ID"
fi

echo "::debug::Base request URL: $base_request_url"

while [ "$deployment_ready" = false ] && [ "$(($(date +%s) - start_time))" -lt "$INPUT_TIMEOUT" ]; do
  # Reset to base URL each time we poll
  request_url="$base_request_url"
  echo "::debug::Requesting deployments from: $request_url"
  
  response=$(curl -s "$request_url" -H "Authorization: Bearer $INPUT_TOKEN") && exit_status=$? || exit_status=$?
  
  if [[ $exit_status -ne 0 ]]; then
    echo "::warning::Failed to get deployment from: $request_url"
    sleep 5  # Add a delay before retrying
    continue
  fi

  error_code=$(echo "$response" | jq -r '.error.code // "none"')

  if [ "$error_code" != "none" ] && [ "$error_code" != "null" ]; then
    if [ "$error_code" = "forbidden" ]; then
      error_message=$(echo "$response" | jq -r '.error.message')
      invalid_token=$(echo "$response" | jq -r '.error.invalidToken')
      
      combined_message="$error_message"
      
      if [ "$invalid_token" = true ]; then
        combined_message+=" (Invalid token detected.)"
      fi
      
      echo "::error::$combined_message"
      exit 1
    else
      echo "::warning::API returned error: $error_code"
    fi
  fi
  
  echo "::debug::Parsing the response from: $request_url"
  
  deployment=$(echo "$response" | jq -r --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA)')
  
  echo "::debug::Found deployment data: $(echo "$deployment" | head -c 100)..."
  
  if [ -n "$deployment" ]; then
    id=$(echo "$deployment" | jq -r '.uid')
    url=$(echo "$deployment" | jq -r '.url')
    state=$(echo "$deployment" | jq -r '.state')
    alias_error=$(echo "$deployment" | jq -r '.aliasError')

    echo "::debug::Deployment state: $state"

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
  else
    echo "::debug::No deployment found with SHA: $INPUT_SHA, waiting..."
  fi

  # If we didn't find the deployment or it's not ready yet, wait before checking again
  sleep 5
done

if [ "$deployment_ready" = false ]; then
  echo "::error::Deployment did not become ready within the specified timeout of: $INPUT_TIMEOUT seconds"
  exit 1
fi
