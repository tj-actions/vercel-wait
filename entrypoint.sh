#!/usr/bin/env bash

set -euo pipefail

# Set a timeout for the loop in seconds
timeout=$INPUT_TIMEOUT

# Start a timer
start_time=$(date +%s)

# Set a flag to indicate whether the deployment is ready
deployment_ready=false

# Loop until the deployment is ready or the timeout is reached
while [ "$deployment_ready" = false ] && [ "$(($(date +%s) - start_time))" -lt "$timeout" ]; do
  # Make the GET request to the Vercel API
  response=$(curl -X GET "https://api.vercel.com/v6/deployments?projectId=$INPUT_PROJECT_ID&teamId=$INPUT_TEAM_ID" -H "Authorization: Bearer $INPUT_TOKEN")

  # Extract the deployment id, url, state, and alias error from the response
  id=$(printf "%s" "$response" | jq --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .uid')
  url=$(printf "%s" "$response" | jq --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .url')
  state=$(printf "%s" "$response" | jq --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .state')
  alias_error=$(printf "%s" "$response" | jq --arg INPUT_SHA "$INPUT_SHA" '.deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .aliasError')

  # If the deployment state is "READY", set the deployment_ready flag to true
  if [ "$state" = "\"READY\"" ]; then
    deployment_ready=true
  fi

  # Sleep for a short duration before making the next request
  sleep "$INPUT_DELAY"
done

# If the deployment is ready, print the deployment id, url, state, and alias error
if [ "$deployment_ready" = true ]; then
  cat <<EOF >>"$GITHUB_OUTPUT"
id=$id
url=$url
state=$state
alias_error=$alias_error
EOF
else
  echo "::error::Deployment did not become ready within the specified timeout of: $timeout seconds"
  exit 1
fi
