#!/usr/bin/env bash

set -euo pipefail

start_time=$(date +%s)

deployment_ready=false

# Validate INPUT_TIMEOUT
if ! [[ "$INPUT_TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo "::error::INPUT_TIMEOUT must be a valid number"
  exit 1
fi

request_url="https://api.vercel.com/v6/deployments?projectId=$INPUT_PROJECT_ID&limit=100"

if [[ -n "$INPUT_TEAM_ID" ]]; then
  request_url="$request_url&teamId=$INPUT_TEAM_ID"
fi

echo "::debug::Retrieving Deployments from: $request_url"

while [ "$deployment_ready" = false ]; do
  elapsed_time=$(($(date +%s) - start_time))
  remaining_time=$((INPUT_TIMEOUT - elapsed_time))

  if [ "$elapsed_time" -ge "$INPUT_TIMEOUT" ]; then
    echo "::error::Timeout reached: $INPUT_TIMEOUT seconds"
    exit 1
  fi

  echo "::debug::Time remaining: $remaining_time seconds"
  echo "::debug::Requesting deployments from: $request_url"

  response=$(curl -s --max-time 10 "$request_url" -H "Authorization: Bearer $INPUT_TOKEN") && exit_status=$? || exit_status=$?

  if [[ $exit_status -ne 0 ]]; then
    echo "::warning::Failed to get deployment from: $request_url"
    break
  fi

  error_code=$(echo "$response" | jq -r '.error.code')

  if [ "$error_code" = "forbidden" ]; then
    error_message=$(echo "$response" | jq -r '.error.message')
    invalid_token=$(echo "$response" | jq -r '.error.invalidToken')

    combined_message="$error_message"

    if [ "$invalid_token" = true ]; then
      combined_message+=" (Invalid token detected.)"
    fi

    echo "::error::$combined_message"
    exit 1
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
    if [[ $request_url == *"&until="* ]]; then
      # If "until" parameter already exists, replace it
      # shellcheck disable=SC2001
      request_url=$(echo "$request_url" | sed "s/until=[0-9]*/until=$next/")
    else
      # If "until" parameter does not exist, add it
      request_url="$request_url&until=$next"
    fi
  else
    break
  fi

  # Sleep for a short interval to avoid spamming requests
  sleep "$INPUT_DELAY"
done

if [ "$deployment_ready" = false ]; then
  echo "::error::Deployment did not become ready within the specified timeout of: $INPUT_TIMEOUT seconds"
  exit 1
fi
