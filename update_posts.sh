#!/usr/bin/env bash

MODIFY_API_URL=${MODIFY_API_URL:-https://api.modifyhq.com}

# Get ID token to authenticate with Modify
echo "Fetching access token"
CREDENTIALS=$(echo -n "${MODIFY_CLIENT_ID}:${MODIFY_CLIENT_SECRET}" | openssl base64 -A)
ACCESS_TOKEN=$(curl "${MODIFY_API_URL}/oauth/token" \
  -H "Authorization: Basic ${CREDENTIALS}" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data "grant_type=client_credentials" \
  | jq -r '.access_token')
AUTH_HEADER="Authorization: Bearer ${ACCESS_TOKEN}"

# Download files
echo "Downloading posts"
QUERY=$(cat <<EOT
query {
  team(slug: \"${TEAM_SLUG}\") {
    workspace(slug: \"${WORKSPACE_SLUG}\") {
      branch(slug: \"${WORKSPACE_BRANCH_SLUG}\") {
        connectorBranch(connectorSlug: \"${CONNECTOR_SLUG}\") {
          downloadTarballUrl(path: \"${CONNECTOR_PATH}\")
        }
      }
    }
  }
}
EOT
)
DOWNLOAD_URL=$(curl "${MODIFY_API_URL}/graphql" \
  -H "${AUTH_HEADER}" \
  -H 'Content-Type: application/json' \
  --data "{\"query\": \"$(echo $QUERY)\"}" \
  | jq -r '.data.team.workspace.branch.connectorBranch.downloadTarballUrl')
curl "${MODIFY_API_URL}${DOWNLOAD_URL}" \
  -H "${AUTH_HEADER}" \
  --output "${RUNNER_TEMP}/modify_files.tar"

# Update posts
pushd ${RUNNER_TEMP}
tar -xf "modify_files.tar"
popd
rm -rf _posts
mv "${RUNNER_TEMP}/${CONNECTOR_PATH}" _posts

# Commit changes
echo "Committing changes"
git config user.name github-actions
git config user.email github-actions@github.com
git add _posts
git diff-index --quiet HEAD || git commit -m "Updating _posts" && git push

# Notify Modify Jobs
MUTATION=$(cat <<EOT
mutation {
  updateJobInstanceStatus(
    id: \"${JOB_INSTANCE_ID}\"
    completed: true
    userStatus: \"done\"
  ) {
    value {
      id
    }
  }
}
EOT
)
if [[ -n "${JOB_INSTANCE_ID}" ]]; then
  echo "Notifying Modify Jobs"
  curl "${MODIFY_API_URL}/graphql" \
    -H "${AUTH_HEADER}" \
    -H 'Content-Type: application/json' \
    --data "{\"query\": \"$(echo $MUTATION)\"}"
fi
