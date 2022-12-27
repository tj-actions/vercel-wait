#!/usr/bin/env bash

set -euo pipefail

start_time=$(date +%s)

deployment_ready=false

url="https://api.vercel.com/v6/deployments?projectId=$INPUT_PROJECT_ID&limit=100"

if [[ -n "$INPUT_TEAM_ID" ]]; then
  url="$url&teamId=$INPUT_TEAM_ID"
fi

while [ "$deployment_ready" = false ] && [ "$(($(date +%s) - start_time))" -lt "$INPUT_TIMEOUT" ]; do
  # Make the GET request to the Vercel API
  response=$(curl -s "$url" -H "Authorization: Bearer $INPUT_TOKEN") || true

  # Extract the deployment id, url, state, and alias error from the response
  id=$(printf "%s" "$response" | jq -r --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .uid')
  url=$(printf "%s" "$response" | jq -r --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .url')
  state=$(printf "%s" "$response" | jq -r --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .state')
  alias_error=$(printf "%s" "$response" | jq -r --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .aliasError')

  if [ "$state" = "READY" ]; then
    deployment_ready=true
    cat <<EOF >>"$GITHUB_OUTPUT"
id=$id
url=$url
state=$state
alias_error=$alias_error
EOF
  fi

  # Sleep for a short duration before making the next request
  sleep "$INPUT_DELAY"
done

if [ "$deployment_ready" = false ]; then
  echo "::error::Deployment did not become ready within the specified timeout of: $INPUT_TIMEOUT seconds"
  exit 1
fi
