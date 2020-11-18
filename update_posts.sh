#!/usr/bin/env bash

MODIFY_API_URL=https://app.modifyhq.com
MODIFY_API_KEY=AIzaSyAUmlhpu52XymA7IjSfeProj0mD_Zp6HI8

# Get ID token to authenticate with Modify
echo "Fetching ID token"
ID_TOKEN=$( \
  curl "https://securetoken.googleapis.com/v1/token?key=${MODIFY_API_KEY}" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data "grant_type=refresh_token&refresh_token=${REFRESH_TOKEN}" \
  | jq -r '.id_token')

# Download files
echo "Downloading posts"
QUERY=$(cat <<EOT
query {
  team(slug: \"${TEAM}\") {
    workspace(slug: \"${WORKSPACE}\") {
      branch(slug: \"${WORKSPACE_BRANCH}\") {
        connectorBranch(connectorSlug: \"${CONNECTOR}\") {
          downloadTarballUrl(path: \"${CONNECTOR_PATH}\") {
            value
            error
          }
        }
      }
    }
  }
}
EOT
)
DOWNLOAD_URL=$( \
  curl "${MODIFY_API_URL}/graphql" \
  -X POST \
  -H "Authorization: Bearer ${ID_TOKEN}" \
  -H 'Content-Type: application/json' \
  --data "{\"query\": \"$(echo $QUERY)\"}" \
  | jq -r '.data.team.workspace.branch.connectorBranch.downloadTarballUrl.value')
curl "${MODIFY_API_URL}${DOWNLOAD_URL}" \
  -H "Authorization: Bearer ${ID_TOKEN}" \
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
    -X POST \
    -H "Authorization: Bearer ${ID_TOKEN}" \
    -H 'Content-Type: application/json' \
    --data "{\"query\": \"$(echo $MUTATION)\"}"
fi
