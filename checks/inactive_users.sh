#!/usr/bin/env bash

uid_min() {

  awk '/^[[:space:]]*UID_MIN/ {print $2; found=1; exit} END {if (!found) print 1000}' "$(hk_path /etc/login.defs)" 2>/dev/null || echo 1000

}

check_inactive_users() {

  local id="USER-001"
  should_run_check "$id" || return 0

  local passwd_file
  passwd_file="$(hk_path /etc/passwd)"

  if [[ ! -f "$passwd_file" ]]; then
    emit_result "$id" "Inactive local human users are reviewed" "medium" "skip" \
      "$passwd_file missing" \
      "Run on a system with a readable passwd database." \
      false false
    return 0
  fi

  local min_uid users
  min_uid="$(uid_min)"

  users="$(
    awk -F: -v min="$min_uid" '$3 >= min && $7 !~ /(nologin|false)$/ {print $1}' "$passwd_file"
  )"

  if [[ -z "$users" ]]; then
    emit_result "$id" "Inactive local human users are reviewed" "medium" "pass" \
      "no local human users found" \
      "No action required." \
      false false
    return 0
  fi

  local inactive=()
  local user

  while IFS= read -r user; do
    [[ -z "$user" ]] && continue

    if command_exists lastlog; then
      if lastlog -u "$user" 2>/dev/null | tail -n +2 | grep -qi 'Never logged in'; then
        inactive+=("$user: never logged in")
      fi
    fi
  done <<< "$users"

  if ((${#inactive[@]})); then
    emit_result "$id" "Inactive local human users are reviewed" "medium" "warn" \
      "$(IFS=', '; echo "${inactive[*]}")" \
      "Review account ownership before locking. Suggested manual command: usermod -L <user>." \
      false false
  else
    emit_result "$id" "Inactive local human users are reviewed" "medium" "pass" \
      "no inactive users detected by available local evidence" \
      "No action required." \
      false false
  fi

}
