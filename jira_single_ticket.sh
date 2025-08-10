#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <docker-image>"
    echo "Example: $0 bkimminich/juice-shop"
    exit 1
fi

IMAGE_NAME="$1"

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found"
    exit 1
fi


if docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "Image found locally: $IMAGE_NAME"
else
    echo "Image not found locally. Attempting to pull: $IMAGE_NAME"
    if ! docker pull "$IMAGE_NAME"; then
        echo "Error: Could not pull image '$IMAGE_NAME'. Please check the name or your Docker login."
        exit 1
    fi
fi



VULN_LIST=$(trivy image "$IMAGE_NAME" \
    --scanners vuln \
    --severity HIGH,CRITICAL \
    --format json |
    jq -r '.Results[].Vulnerabilities[] |
        "- \(.Severity): \(.Title)\n  Description: \(.Description)\n"' )


TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")


DEP_PR=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/pulls?state=open" \
    | jq -r '[.[] | select(.user.login=="dependabot[bot]")][0].html_url')

# If there is no Dependabot PR, leave it empty
if [ "$DEP_PR" = "null" ] || [ -z "$DEP_PR" ]; then
    DEP_PR_TEXT="No related Dependabot PR found."
else
    DEP_PR_TEXT="Related Dependabot PR: $DEP_PR"
fi


jq -n \
  --arg project "$PROJECT_KEY" \
  --arg summary "$IMAGE_NAME - $TIMESTAMP: High/Critical Vulnerabilities Trivy Security Scan" \
  --arg description "$(printf "%s\n\n%s" "$VULN_LIST" "$DEP_PR_TEXT")" \
  '{
    fields: {
      project: { key: $project },
      summary: $summary,
      description: $description,
      issuetype: { name: "Task" },
      labels: ["Trivy", "Vulnerability", "Scan"]
    }
  }' |
curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "$EMAIL:$API_TOKEN" \
  --data @- \
  "$JIRA_URL/rest/api/2/issue/" | jq .



echo "=========== SCAN AND JIRA DONE =========="
