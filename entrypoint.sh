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

  read -r id url state alias_error < <(curl -s "$url" -H "Authorization: Bearer $INPUT_TOKEN" | jq -r --arg INPUT_SHA "$INPUT_SHA" '[
    .deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .uid,
    .deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .url,
    .deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .state,
    .deployments[] | select(.meta.githubCommitSha==$INPUT_SHA) | .aliasError
  ] | join(" ")')

  if [ "$state" = "READY" ]; then
    deployment_ready=true
    cat <<EOF >>"$GITHUB_OUTPUT"
id=$id
url=$url
state=$state
alias_error=$alias_error
EOF
  fi

  echo "::warning::Unable to retrieve deployment sleeping for: $INPUT_DELAY seconds"

  sleep "$INPUT_DELAY"
done

if [ "$deployment_ready" = false ]; then
  echo "::error::Deployment did not become ready within the specified timeout of: $INPUT_TIMEOUT seconds"
  exit 1
fi
