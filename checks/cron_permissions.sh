#!/usr/bin/env bash

check_cron_permissions() {

    local id="CRON-001"

    should_run_check "$id" || return 0

    local paths=(
    /etc/crontab
    /etc/cron.d
    /etc/cron.hourly
    /etc/cron.daily
    /etc/cron.weekly
    /etc/cron.monthly
    /var/spool/cron
    /var/spool/cron/crontabs
    )

    local existing=()
    local p

    for p in "${paths[@]}"; do

    local hp

    hp="$(hk_path "$p")"
    [[ -e "$hp" ]] && existing+=("$hp")

    done

    if ((${#existing[@]} == 0)); then
    emit_result "$id" "Cron files are not group/world writable" "high" "skip" \
        "no cron paths found" \
        "Verify cron implementation and system scheduler." \
        true false
    return 0
    fi

    local findings

    findings="$(
    find "${existing[@]}" \( -type f -o -type d \) -perm /022 -print 2>/dev/null
    )"

    if [[ -z "$findings" ]]; then
    emit_result "$id" "Cron files are not group/world writable" "high" "pass" \
        "no group/world writable cron files found" \
        "No action required." \
        true false
    return 0
    fi

    local changed = false

    if [[ "$FIX" -eq 1 ]]; then
    require_root_for_fix
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        backup_file "$item"
        apply_cmd "remove group/other write from $item" chmod go-w "$item"
    done <<< "$findings"
    changed=true
    fi

    emit_result "$id" "Cron files are not group/world writable" "high" "fail" \
    "$findings" \
    "Remove group/other write permission from system cron files and verify owners." \
    true "$changed"

}