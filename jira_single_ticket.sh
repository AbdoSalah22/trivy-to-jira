#!/bin/bash


IMAGE_NAME=""
REPO_NAME=""


while [[ "$#" -gt 0 ]]; do
    case $1 in
        --image) IMAGE_NAME="$2"; shift ;;
        --repo)  REPO_NAME="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


if [ -z "$IMAGE_NAME" ]; then
    echo "Usage: $0 --image <docker-image> [--repo <github-repo>]"
    echo "Example: $0 --image bkimminich/juice-shop --repo AbdoSalah22/trivy-to-jira"
    exit 1
fi


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


DEP_PR_TEXT=""
if [ -n "$REPO_NAME" ]; then
    echo "[INFO] Checking for Dependabot PRs in $REPO_NAME"

    DEP_PR_URL=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO_NAME/pulls?state=open" |
        jq -r '
          [.[] | select(.user.login=="dependabot[bot]")][0].html_url
        ')

    if [ "$DEP_PR_URL" != "null" ] && [ -n "$DEP_PR_URL" ]; then
        DEP_PR_TEXT="Related Dependabot PR: $DEP_PR_URL"
    else
        DEP_PR_TEXT="No related Dependabot PR found."
    fi
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
