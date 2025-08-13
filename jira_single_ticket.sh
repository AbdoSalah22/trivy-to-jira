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


: "${JIRA_PROJECT_KEY:?JIRA_PROJECT_KEY not set}"
: "${JIRA_EMAIL:?JIRA_EMAIL not set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN not set}"
: "${JIRA_URL:?JIRA_URL not set}"
: "${GH_TOKEN:?GH_TOKEN not set}"


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
        "- \(.Severity): \(.Title)
  Installed: \(.InstalledVersion)
  Fixed: \(.FixedVersion // "N/A")
  Help: \(.PrimaryURL)
"'
)


DEP_PR_TEXT=""
if [ -n "$REPO_NAME" ]; then
    echo "[INFO] Checking for Dependabot PRs in $REPO_NAME"

    RESPONSE=$(curl -s \
        -H "Authorization: token $GH_TOKEN" \
        "https://api.github.com/repos/$REPO_NAME/pulls?state=open")

    # Check if repo exists
    if echo "$RESPONSE" | jq -e '.message? | contains("Not Found")' >/dev/null; then
        echo "[ERROR] Repository '$REPO_NAME' not found or inaccessible."
        DEP_PR_TEXT="Repository not found or inaccessible."
	exit 1
    else
        DEP_PR_URLS=$(echo "$RESPONSE" | jq -r '.[] | select(.user.login=="dependabot[bot]").html_url')

        if [ -n "$DEP_PR_URLS" ]; then
            DEP_PR_TEXT="Related Dependabot PRs:"
            while IFS= read -r url; do
                DEP_PR_TEXT="$DEP_PR_TEXT\n- $url"
            done <<< "$DEP_PR_URLS"
        else
            DEP_PR_TEXT="No related Dependabot PR found."
        fi
    fi
fi

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

jq -n \
  --arg project "$JIRA_PROJECT_KEY" \
  --arg summary "$IMAGE_NAME - $TIMESTAMP: Trivy Vulnerabilities Scan Report" \
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
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  --data @- \
  "$JIRA_URL/rest/api/2/issue/" | jq .


echo "=========== SCAN AND JIRA DONE =========="
