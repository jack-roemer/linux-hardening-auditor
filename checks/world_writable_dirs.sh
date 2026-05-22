#!/usr/bin/env bash

check_world_writable_dirs() {
  local id="FS-001"
  should_run_check "$id" || return 0

  local root
  root="${HK_ROOT:-/}"

  local xdev=()
  [[ "${SCAN_ONE_FILESYSTEM:-1}" -eq 1 ]] && xdev=(-xdev)

  local max="${WORLD_WRITABLE_MAX_RESULTS:-50}"
  local findings

  findings="$(
    find "$root" "${xdev[@]}" \
      \( -path "$root/proc" -o -path "$root/sys" -o -path "$root/dev" -o -path "$root/run" \) -prune -o \
      -type d -perm -0002 ! -perm -1000 -print 2>/dev/null |
      head -n "$max"
  )"

  if [[ -z "$findings" ]]; then
    emit_result "$id" "World-writable directories have sticky bit" "medium" "pass" \
      "no findings" \
      "No action required." \
      true false
    return 0
  fi

  local changed=false
  if [[ "$FIX" -eq 1 ]]; then
    require_root_for_fix

    while IFS= read -r dir; do
      [[ -z "$dir" ]] && continue
      apply_cmd "set sticky bit on $dir" chmod +t "$dir"
    done <<< "$findings"

    changed=true
  fi

  emit_result "$id" "World-writable directories have sticky bit" "medium" "fail" \
    "$findings" \
    "Set the sticky bit on legitimate shared directories or remove world-write permission where not required." \
    true "$changed"
}
