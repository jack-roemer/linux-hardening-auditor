#!/usr/bin/env bash

check_sudoers_permissions() {
  
  local id="SUDO-001"
  should_run_check "$id" || return 0

  local file
  file="$(hk_path /etc/sudoers)"

  if [[ ! -e "$file" ]]; then
    emit_result "$id" "sudoers file has safe permissions" "high" "skip" \
      "$file missing" \
      "Verify whether sudo is installed and managed by another policy mechanism." \
      true false
    return 0
  fi

  local uid mode
  uid="$(stat -c '%u' "$file")"
  mode="$(stat -c '%a' "$file")"

  local status="pass"
  local evidence="uid=$uid mode=$mode"

  if [[ "$uid" != "0" || "$mode" != "440" ]]; then
    status="fail"
  fi

  local changed=false
  if [[ "$status" == "fail" && "$FIX" -eq 1 ]]; then
    require_root_for_fix
    backup_file "$file"
    apply_cmd "set sudoers owner" chown root:root "$file"
    apply_cmd "set sudoers mode" chmod 0440 "$file"

    if [[ "$DRY_RUN" -eq 0 ]] && command_exists visudo; then
      visudo -cf "$file" >/dev/null || {
        emit_result "$id" "sudoers file has safe permissions" "high" "error" \
          "visudo validation failed after permission change" \
          "Restore from backup and inspect sudoers syntax." \
          true false
        return 0
      }
    fi
    changed=true
  fi

  emit_result "$id" "sudoers file has safe permissions" "high" "$status" \
    "$evidence" \
    "Ensure /etc/sudoers is owned by root and mode 0440; validate syntax with visudo -c." \
    true "$changed"

}
