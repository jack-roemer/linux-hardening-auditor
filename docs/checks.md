# Check reference

This document explains what each check inspects, how pass/fail decisions are made, and how remediation behaves. The goal is to make the auditor easy to review and safe to extend.

## Check summary

| ID | Check | Risk | Auto-fix | Notes |
|---|---|---:|---|---|
| SSH-001 | SSH root login disabled | High | Gated | Avoids lockout by requiring profile opt-in |
| SSH-002 | SSH password authentication disabled | High | Gated | Requires key-based access review first |
| SUDO-001 | sudoers ownership and mode | High | Yes | Validates with `visudo` when available |
| USER-001 | inactive local human users reviewed | Medium | No | Audit-only because account ownership needs context |
| FS-001 | world-writable directories have sticky bit | Medium | Yes, scoped | Adds sticky bit to detected directories |
| FW-001 | host firewall active | Medium | No | Audit-only because network changes can break access |
| UMASK-001 | default umask is restrictive | Low | Yes | Updates `/etc/login.defs` |
| DOCKER-001 | Docker socket not broadly exposed | Critical | Partial | Restricts socket mode when applicable |
| CRON-001 | cron files not group/world writable | High | Yes, scoped | Removes group/other write bits |

## SSH-001: SSH root login disabled

**Risk:** High  
**Files/commands inspected:** `sshd -T -C user=root,host=localhost,addr=127.0.0.1`  
**Pass condition:** Effective `permitrootlogin` is `no`.  
**Warn condition:** Effective value is partially restricted, such as `prohibit-password` or `forced-commands-only`.  
**Fail condition:** Effective value allows direct root login.  
**Fix behavior:** Writes `PermitRootLogin no` to `/etc/ssh/sshd_config.d/00-hardenkit.conf` only when `--fix` is used and `AUTO_FIX_SSH=1`.  
**Safety notes:** SSH changes can lock out administrators. Confirm a working non-root sudo account and key-based login before enabling SSH auto-fix.

## SSH-002: SSH password authentication disabled

**Risk:** High  
**Files/commands inspected:** `sshd -T -C user=root,host=localhost,addr=127.0.0.1`  
**Pass condition:** Effective `passwordauthentication` is `no`.  
**Fail condition:** Password authentication is enabled.  
**Fix behavior:** Writes `PasswordAuthentication no` to the hardenkit SSH drop-in only when `--fix` is used and `AUTO_FIX_SSH=1`.  
**Safety notes:** Confirm SSH key access before applying. Some environments also require reviewing PAM and keyboard-interactive settings.

## SUDO-001: sudoers ownership and mode

**Risk:** High  
**Files/commands inspected:** `/etc/sudoers`, `stat`, optional `visudo -cf`.  
**Pass condition:** File is owned by UID `0` and mode is `0440`.  
**Fail condition:** File is not root-owned or has unexpected permissions.  
**Fix behavior:** Runs `chown root:root` and `chmod 0440`, then validates syntax with `visudo` when available.  
**Rollback notes:** Use `--backup DIR` to preserve the original file before changing it.

## USER-001: inactive local human users reviewed

**Risk:** Medium  
**Files/commands inspected:** `/etc/passwd`, `/etc/login.defs`, optional `lastlog`.  
**Pass condition:** No inactive local human users are detected by available local evidence.  
**Warn condition:** One or more local human users appear to have never logged in.  
**Fix behavior:** None by default.  
**False positives:** Break-glass accounts, service owner accounts, contractor accounts, and centrally managed users may require manual review.

## FS-001: world-writable directories have sticky bit

**Risk:** Medium  
**Files/commands inspected:** `find` over `/` or the supplied `--root` path.  
**Pass condition:** No world-writable directories without the sticky bit are found.  
**Fail condition:** One or more world-writable directories lack the sticky bit.  
**Fix behavior:** Adds the sticky bit with `chmod +t` to each detected directory.  
**False positives:** Application directories may intentionally use unusual permissions, but those cases should be documented and reviewed.

## FW-001: host firewall active

**Risk:** Medium  
**Files/commands inspected:** `ufw status`, `firewall-cmd --state`, `nft list ruleset`.  
**Pass condition:** UFW is active or firewalld is running.  
**Warn condition:** nftables rules exist, but policy strength is not evaluated.  
**Fail condition:** No supported firewall state is detected.  
**Fix behavior:** None by default.  
**Safety notes:** Enabling a firewall automatically can break SSH or application access. This check intentionally reports only.

## UMASK-001: default umask is restrictive

**Risk:** Low  
**Files/commands inspected:** `/etc/login.defs`.  
**Pass condition:** `UMASK` equals the configured `BASELINE_UMASK`, default `027`.  
**Fail condition:** `UMASK` is missing or weaker than the baseline value.  
**Fix behavior:** Updates or appends the `UMASK` setting in `/etc/login.defs`.  
**False positives:** PAM, shell startup files, and distribution-specific defaults may override this value.

## DOCKER-001: Docker socket not broadly exposed

**Risk:** Critical  
**Files/commands inspected:** `/var/run/docker.sock`, `ss`, optional `docker ps` and `docker inspect`.  
**Pass condition:** The socket is not world-accessible, TCP port `2375` is not detected, and running containers are not mounting the socket.  
**Fail condition:** The Docker socket is world-accessible, the unauthenticated API appears exposed, or containers mount the socket.  
**Fix behavior:** Restricts socket mode to `0660` when a local socket exists.  
**Safety notes:** Membership in the Docker group can be equivalent to high host privilege. Review group membership separately.

## CRON-001: cron files not group/world writable

**Risk:** High  
**Files/commands inspected:** `/etc/crontab`, `/etc/cron.d`, periodic cron directories, and common spool paths.  
**Pass condition:** No checked cron file or directory is group/world writable.  
**Fail condition:** A cron file or directory is group/world writable.  
**Fix behavior:** Removes group and other write bits with `chmod go-w`.  
**Rollback notes:** Use `--backup DIR` before fixing production hosts.
