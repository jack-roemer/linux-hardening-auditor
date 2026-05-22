#!/usr/bin/env bash

check_umask() {
  
  local id="UMASK-001"
  should_run_check "$id" || return 0

  local file
  file="$(hk_path /etc/login.defs)"
  local desired="${BASELINE_UMASK:-027}"

  if [[ ! -f "$file" ]]; then
    emit_result "$id" "Default umask is restrictive" "low" "skip" \
      "$file missing" \
      "Check shell, PAM, and distribution-specific umask configuration." \
      true false
    return 0
  fi

  local current
  current="$(awk '/^[[:space:]]*UMASK[[:space:]]+/ {print $2; exit}' "$file")"

  if [[ "$current" == "$desired" ]]; then
    emit_result "$id" "Default umask is restrictive" "low" "pass" \
      "UMASK $current" \
      "No action required." \
      true false
    return 0
  fi

  local changed=false
  if [[ "$FIX" -eq 1 ]]; then
    require_root_for_fix
    ensure_kv_line "$file" "UMASK" "$desired"
    changed=true
  fi

  emit_result "$id" "Default umask is restrictive" "low" "fail" \
    "UMASK ${current:-not set}; expected $desired" \
    "Set UMASK $desired in /etc/login.defs and review PAM/shell-specific overrides." \
    true "$changed"

}
