# Docker Image Vulnerability Scanner to Jira with Dependabot Integration

This Bash script scans a Docker image for **HIGH** and **CRITICAL** vulnerabilities using [Trivy](https://github.com/aquasecurity/trivy), then automatically creates a Jira ticket with the findings.
If a GitHub repository is provided, it also checks for an **open Dependabot pull request** related to that image and includes the link in the Jira ticket.

---

## 📋 Features

* **Scans local or remote Docker images** with Trivy.
* **Auto-creates Jira tasks** containing:

  * Vulnerability details
  * Timestamp
  * Labels for tracking
* **Integrates with GitHub Dependabot** to link related PRs.
* **Validates repository existence** before querying GitHub.
* Works with **custom and public images**.

---

## 🛠 Prerequisites

Before using the script, ensure you have:

1. **Docker** installed and running:

   ```bash
   docker --version
   ```

2. **Trivy** installed:

   ```bash
   trivy --version
   ```

3. **jq** installed:

   ```bash
   jq --version
   ```

4. A `.env` file with Jira and GitHub credentials:

   ```env
   PROJECT_KEY=YOUR_JIRA_PROJECT_KEY
   EMAIL=your_email@example.com
   API_TOKEN=your_jira_api_token
   JIRA_URL=https://your-domain.atlassian.net
   GITHUB_TOKEN=your_github_personal_access_token
   ```

---

## 🚀 Usage

```bash
bash jira_single_ticket.sh --image <docker-image> [--repo <github-owner/repo>]
```

### Arguments:

| Flag      | Required | Description                                                              |
| --------- | -------- | ------------------------------------------------------------------------ |
| `--image` | ✅        | Docker image name (local or remote) — e.g., `nginx:latest` or `myapp:v1` |
| `--repo`  | ❌        | GitHub repository in `owner/repo` format for Dependabot PR checks        |

---

## 📄 What Happens

1. **Image Check** → If the image exists locally, it’s scanned directly; if not, it’s pulled from the registry.
2. **Trivy Scan** → Vulnerabilities are fetched in JSON and filtered to show only **HIGH** and **CRITICAL** severities.
3. **Dependabot Check** (optional) → If `--repo` is given:

   * Queries GitHub API for open PRs.
   * Filters for PRs created by `dependabot[bot]`.
   * Validates if the repo exists.
4. **Jira Ticket Creation** → Posts the scan results to Jira with labels for easy tracking.

---

## ⚠ Error Handling

* If the **Docker image** doesn’t exist remotely, it will skip the pull and exit with an error.
* If the **GitHub repo** is wrong or inaccessible, it will warn you and still create the Jira ticket without Dependabot info.
* If **no Dependabot PRs** match, the ticket will note that.

---

## 📌 Example Jira Ticket Description

```
- CRITICAL: Vulnerability in OpenSSL
  Description: A buffer overflow was found...
  
Related Dependabot PR: https://github.com/my-org/my-repo/pull/42
```

