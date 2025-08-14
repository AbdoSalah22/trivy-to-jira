# Docker Image Vulnerability Scanner to Jira with Dependabot & GitHub Actions Integration

This project automates vulnerability scanning for Docker images using [Trivy](https://github.com/aquasecurity/trivy), then creates or updates a **single Jira ticket** per image with the findings. It also integrates with **Dependabot** and leverages **GitHub Actions** for CI/CD security workflows.

---

## 📋 Features

* **Scans Docker images** (local or remote) for **HIGH** and **CRITICAL** vulnerabilities.
* **Creates or updates a fixed Jira task** for each image:
  * If a ticket with the format `<image-name> Security Scan Report` exists, its description is overwritten with the latest scan results.
  * If not, a new ticket is created.
  * Vulnerability details, timestamp (in global UTC), and related Dependabot PRs are included.
  * Labels for tracking are added.
* **Dependabot integration**:
  * Checks for open Dependabot PRs in the specified GitHub repo.
  * Includes PR links in Jira tickets.
  * Dependabot is configured to group all updates for each ecosystem into a single PR (see `.github/dependabot.yml`).
* **GitHub Actions workflow**:
  * Automated security scans via `.github/workflows/security-scan.yml`.
  * Can trigger Trivy scans and ticket creation/update as part of CI/CD.
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
bash jira_single_ticket.sh --image <docker-image> --repo <github-owner/repo>
```

| Flag      | Required | Description                                                              |
| --------- | -------- | ------------------------------------------------------------------------ |
| `--image` | ✅        | Docker image name (local or remote) — e.g., `nginx:latest` or `myapp:v1` |
| `--repo`  | ✅        | GitHub repository in `owner/repo` format for Dependabot PR checks        |

> **Note:** Both `--image` and `--repo` are required.

### Automated Workflow

* **GitHub Actions**: See `.github/workflows/security-scan.yml` for automated scanning and ticket creation/update.
* **Dependabot**: Configuration in `.github/dependabot.yml` now groups all updates for each ecosystem into a single PR.

---

## 📄 How It Works

1. **Image Check**: Uses Docker to verify/pull the image.
2. **Trivy Scan**: Scans for vulnerabilities, filters for HIGH/CRITICAL, outputs JSON.
3. **Dependabot PR Check**: Queries GitHub for open Dependabot PRs and validates repo access.
4. **Jira Ticket Handling**:
   * Searches Jira for a ticket with summary `<image-name> Security Scan Report`.
   * If found, updates the description with the latest scan results, timestamp (UTC), and PR info.
   * If not found, creates a new ticket.
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
Scanned at: 2025-08-14 12:00:00 UTC

- CRITICAL: Vulnerability in OpenSSL
  Installed: 1.1.1
  Fixed: 1.1.1g
  Help: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-XXXX-XXXX

Related Dependabot PRs:
- https://github.com/my-org/my-repo/pull/42
```

---

## 🔗 References

* [Trivy Documentation](https://aquasecurity.github.io/trivy/)
* [Jira REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v2/)
* [Dependabot](https://docs.github.com/en/code-security/dependabot)
* [GitHub Actions](https://docs.github.com/en/actions)