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

docker pull "$IMAGE_NAME"


VULN_LIST=$(trivy image "$IMAGE_NAME" \
    --scanners vuln \
    --severity HIGH,CRITICAL \
    --format json |
    jq -r '.Results[].Vulnerabilities[] |
        "- \(.Severity): \(.Title)\n  Description: \(.Description)\n"' )

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

jq -n \
  --arg project "$PROJECT_KEY" \
  --arg summary "$IMAGE_NAME - $TIMESTAMP: High/Critical Vulnerabilities Trivy Security Scan" \
  --arg description "$VULN_LIST" \
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
