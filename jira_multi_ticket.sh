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

trivy image "$IMAGE_NAME" \
    --scanners vuln \
    --severity HIGH,CRITICAL \
    --format json |
    jq -c '.Results[].Vulnerabilities[] | {Title: .Title, Description: .Description, Severity: .Severity}' |
while read -r vuln; do
    TITLE=$(echo "$vuln" | jq -r '.Title')
    DESCRIPTION=$(echo "$vuln" | jq -r '.Description')
    SEVERITY=$(echo "$vuln" | jq -r '.Severity')

    echo "Creating Jira ticket for: $TITLE"

    curl -s -X POST \
      -H "Content-Type: application/json" \
      -u "$EMAIL:$API_TOKEN" \
      --data "{
        \"fields\": {
           \"project\": { \"key\": \"$PROJECT_KEY\" },
           \"summary\": \"$IMAGE_NAME: $SEVERITY - $TITLE\",
           \"description\": \"$DESCRIPTION\",
           \"issuetype\": { \"name\": \"Task\" },
           \"labels\": [\"Trivy\", \"Vulnerability\", \"$SEVERITY\"]
         }
      }" \
      "$JIRA_URL/rest/api/2/issue/" \
	| jq .
done

echo "=========== SCAN AND JIRA DONE =========="
