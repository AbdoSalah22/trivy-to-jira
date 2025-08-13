# Docker Image Vulnerability Scanner to Jira with Dependabot & GitHub Actions Integration

This project automates vulnerability scanning for Docker images using [Trivy](https://github.com/aquasecurity/trivy), then creates a Jira ticket with the findings. It also integrates with **Dependabot** and leverages **GitHub Actions** for CI/CD security workflows.

---

## 📋 Features

* **Scans Docker images** (local or remote) for **HIGH** and **CRITICAL** vulnerabilities.
* **Creates Jira tasks** with:
  * Vulnerability details
  * Timestamp
  * Labels for tracking
* **Dependabot integration**:
  * Checks for open Dependabot PRs in the specified GitHub repo.
  * Includes PR links in Jira tickets.
  * Improved configuration via `.github/dependabot.yml`.
* **GitHub Actions workflow**:
  * Automated security scans via `.github/workflows/security-scan.yml`.
  * Can trigger Trivy scans and ticket creation as part of CI/CD.
* **Robust error handling** for missing images, inaccessible repos, and missing PRs.

---

## 🛠 Prerequisites

Ensure you have:

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
4. **GitHub Secrets** configured for Jira and GitHub credentials:
   - Set the following secrets in your repository:
     - `JIRA_PROJECT_KEY`
     - `JIRA_EMAIL`
     - `JIRA_API_TOKEN`
     - `JIRA_URL`
     - `GH_TOKEN`

---

## 🚀 Usage

### Manual Script

```bash
bash jira_single_ticket.sh --image <docker-image> [--repo <github-owner/repo>]
```

| Flag      | Required | Description                                                              |
| --------- | -------- | ------------------------------------------------------------------------ |
| `--image` | ✅        | Docker image name (local or remote) — e.g., `nginx:latest` or `myapp:v1` |
| `--repo`  | ❌        | GitHub repository in `owner/repo` format for Dependabot PR checks        |

### Automated Workflow

* **GitHub Actions**: See `.github/workflows/security-scan.yml` for automated scanning and ticket creation.
* **Dependabot**: Configuration in `.github/dependabot.yml` ensures dependencies are regularly checked and PRs are created for updates.

---

## 📄 How It Works

1. **Image Check**: Uses Docker to verify/pull the image.
2. **Trivy Scan**: Scans for vulnerabilities, filters for HIGH/CRITICAL, outputs JSON.
3. **Dependabot PR Check**: If `--repo` is provided, queries GitHub for open Dependabot PRs and validates repo access.
4. **Jira Ticket Creation**: Posts scan results and PR info to Jira.
5. **GitHub Actions**: Automates the above steps for CI/CD pipelines.

---

## ⚠ Error Handling

* **Image not found**: Attempts to pull, exits if unavailable.
* **Repo inaccessible**: Warns and exits if the repo is not found.
* **No Dependabot PRs**: Notes absence in Jira ticket.
* **Environment variables**: Script checks for required variables and exits if missing.

---

## 📁 Project Structure

```
.
├── jira_single_ticket.sh           # Main Bash script
├── README.md                       # This documentation
├── .github/
│   ├── dependabot.yml              # Dependabot configuration
│   └── workflows/
│       └── security-scan.yml       # GitHub Actions workflow
```

---

## 📌 Example Jira Ticket Description

```
- CRITICAL: Vulnerability in OpenSSL
  Installed: 1.1.1
  Fixed: 1.1.1g
  Help: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-XXXX-XXXX

Related Dependabot PR: https://github.com/my-org/my-repo/pull/42
```

---

## 🔗 References

* [Trivy Documentation](https://aquasecurity.github.io/trivy/)
* [Jira REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v2/)
* [Dependabot](https://docs.github.com/en/code-security/dependabot)
* [GitHub Actions](https://docs.github.com/en/actions)