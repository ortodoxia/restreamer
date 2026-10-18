# Security Policy

## Supported Versions

This fork maintains the patched image built from the `2.x` branch and published to `ghcr.io/ortodoxia/restreamer`. Historical upstream tags are not covered by this fork's maintenance.

The release workflow audits every architecture and blocks publication on high or critical dependency findings. It rebuilds OS packages weekly; Dependabot proposes dependency and action updates. Scanner results are point-in-time evidence, not a guarantee that the application is vulnerability-free.

Keep authentication enabled for internet-facing deployments. Back up configuration and data before upgrading and review the image's codec compatibility notes in the README.

## Reporting a Vulnerability

For fork-specific vulnerabilities, use this repository's private vulnerability reporting feature if enabled. Do not post access tokens, stream keys, or exploit details in public issues. Upstream Restreamer/Core issues can be reported privately to support@datarhei.com.

We treat security issues with confidentiality until controlled and disclosed responsibly.
