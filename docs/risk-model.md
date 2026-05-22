# Risk model

This project uses a simple severity model so findings are easy to triage. Severity reflects the likely security impact of a misconfiguration, not the certainty of exploitation in every environment.

## Critical

A finding is critical when it can reasonably lead to broad host compromise or root-equivalent control.

Example:

- A broadly exposed Docker socket.

## High

A finding is high risk when it weakens administrative access controls, root-executed configuration, or privilege boundaries.

Examples:

- SSH root login is allowed.
- SSH password authentication is enabled.
- `/etc/sudoers` has unsafe permissions.
- Cron files executed by privileged users are group/world writable.

## Medium

A finding is medium risk when it is important hardening context but may depend heavily on the host role, network environment, or business process.

Examples:

- No supported host firewall appears active.
- Local human users appear inactive or never used.
- World-writable directories lack the sticky bit.

## Low

A finding is low risk when it is mainly defense-in-depth or baseline hygiene.

Example:

- The default umask is weaker than the selected profile baseline.

## Status definitions

| Status | Meaning |
|---|---|
| pass | The host appears to satisfy the check. |
| fail | The host does not satisfy the check. |
| warn | The result needs review because context matters. |
| skip | The check could not run because a required file or command was missing. |
| error | The check or remediation failed unexpectedly. |
| info | Informational output only. |

## Remediation principles

Remediation should be:

1. **Explicit:** fixes only run when `--fix` is supplied.
2. **Previewable:** `--dry-run` shows intended actions before changes are made.
3. **Backed up:** `--backup DIR` preserves files before edits.
4. **Idempotent:** running the same fix repeatedly should not duplicate lines or keep changing the same file.
5. **Scoped:** fixes should change the smallest practical surface area.
6. **Validated:** service configuration changes should be validated before reload when possible.

## Why some checks are audit-only

Some controls are intentionally not remediated by default. For example, enabling a firewall or disabling SSH password authentication can break legitimate access if done without environment-specific planning. Those checks produce evidence and recommendations but require an administrator to decide when and how to apply the change.
