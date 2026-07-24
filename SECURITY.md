# Security Policy

## Supported Versions

Only the latest released version of Barruu receives security updates.

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

We do not backport security fixes to older major versions. Users are expected to stay reasonably up-to-date.

## Reporting a Vulnerability

The Barruu team takes security vulnerabilities seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please send an email to:

**[security@barruu.com](mailto:security@barruu.com)**

Please include the following information in your report:

- A clear description of the vulnerability
- Steps to reproduce the issue
- Affected versions
- Potential impact
- Any suggested mitigations or fixes (if available)

### What to Expect

1. **Acknowledgment**: You will receive an acknowledgment of your report within **48 hours**.

1. **Investigation**: The team will investigate and validate the issue. We may ask for additional information during this phase.

1. **Resolution Timeline**:
   - **Critical** vulnerabilities: Fix targeted within **72 hours**, with an out-of-band release if necessary.
   - **High** severity: Fix targeted within **7 days**.
   - **Medium** severity: Fix targeted within **30 days**, included in the next scheduled release.
   - **Low** severity: Fix targeted within **90 days**, included in a future release.

1. **Disclosure**: We follow coordinated disclosure. Once a fix is available, we will:
   - Publish a security advisory on GitHub
   - Credit the reporter (unless anonymity is requested)
   - Release a patched version

### Severity Classification

| Severity | Description                                                                           |
| -------- | ------------------------------------------------------------------------------------- |
| Critical | Remote code execution, data exfiltration without user interaction, privilege escalation |
| High     | Data leakage requiring user interaction, denial of service, authentication bypass     |
| Medium   | Cross-site scripting (if applicable), CSRF, information disclosure (limited)          |
| Low      | Minor issues, theoretical exploits, best practice violations                          |

### Bug Bounty

At this time, Barruu does not offer a paid bug bounty program. However, we will publicly acknowledge your contribution in our security advisory and (with your permission) in the project's contributors list.

## Security Best Practices for Users

### Keeping Your Data Safe

Barruu is an offline-first application. Your data is stored locally on your device by default. To keep your data secure:

- **Encrypt your device storage** — Use full-disk encryption on your operating system
- **Keep Barruu updated** — Always use the latest version for security patches
- **Be cautious with plugins** — Only install plugins from trusted sources
- **Backup your data** — Regularly export and backup important documents

### Dependencies

We use Dependabot and automated scanning to keep dependencies up-to-date. However, if you notice an outdated dependency with a known CVE, please report it via the process above.

## Security Features

Barruu includes the following security features:

- **Offline-first architecture**: Your data stays on your device
- **Local encryption**: Data at rest is encrypted via SQLite encryption extensions (planned)
- **No telemetry**: Barruu does not collect or send usage data
- **Open source**: The entire codebase is publicly auditable under the AGPL-3.0 license

---

Thank you for helping keep Barruu and its users secure. 🔒
