#!/usr/bin/env bash

check_ssh_password_auth() {
  
  local id="SSH-002"
  should_run_check "$id" || return 0

  local value
  if ! value="$(sshd_effective_value passwordauthentication)"; then
    emit_result "$id" "SSH password authentication is disabled" "high" "skip" \
      "sshd not available or configuration unreadable" \
      "Install OpenSSH server or run with privileges that can inspect sshd configuration." \
      true false
    return 0
  fi

  if [[ "$value" == "no" ]]; then
    emit_result "$id" "SSH password authentication is disabled" "high" "pass" \
      "passwordauthentication no" \
      "No action required." \
      true false
  else
    local changed=false
    if [[ "$FIX" -eq 1 && "${AUTO_FIX_SSH:-0}" -eq 1 ]]; then
      if fix_sshd_option "PasswordAuthentication" "no"; then
        changed=true
      fi
    fi

    emit_result "$id" "SSH password authentication is disabled" "high" "fail" \
      "passwordauthentication $value" \
      "Confirm key-based login and sudo access, then set PasswordAuthentication no." \
      true "$changed"
  fi

}
