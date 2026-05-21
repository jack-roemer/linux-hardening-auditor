#!/usr/bin/env bash

sshd_effective_value() {

    local key="$1"

    if ! command_exists sshd; then
    return 127
    fi

    sshd -T -C user=root,host=localhost,addr=127.0.0.1 2>/dev/null |
    awk -v k="$key" '$1 == k {print $2; exit}'

}

fix_sshd_option() {

    local key="$1"
    local value="$2"
    local dropin

    require_root_for_fix

    dropin = "$(hk_path /etc/ssh/sshd_config.d/00-hardenkit.conf)"
    ensure_kv_line "$dropin" "$key" "$value"

    if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
    fi

    if ! sshd -t; then
    echo "sshd validation failed after setting $key $value" >&2
    return 1
    fi

    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || true

    local effective
    effective="$(sshd_effective_value "$(tr '[:upper:]' '[:lower:]' <<< "$key")")"

    [[ "$effective" == "$value" ]]

}

check_ssh_root_login() {

    local id="SSH-001"

    should_run_check "$id" || return 0

    local value

    if ! value="$(sshd_effective_value permitrootlogin)"; then
    emit_result "$id" "SSH root login is disabled" "high" "skip" \
        "sshd not available or configuration unreadable" \
        "Install OpenSSH server or run with privileges that can inspect sshd configuration." \
        true false
    return 0
    fi

    case "$value" in
    no)
        emit_result "$id" "SSH root login is disabled" "high" "pass" \
        "permitrootlogin no" \
        "No action required." \
        true false
        ;;
    prohibit-password|forced-commands-only)
        emit_result "$id" "SSH root login is fully disabled" "high" "warn" \
        "permitrootlogin $value" \
        "For stricter baseline hardening, set PermitRootLogin no." \
        true false
        ;;
    *)
        local changed=false
        if [[ "$FIX" -eq 1 && "${AUTO_FIX_SSH:-0}" -eq 1 ]]; then
        if fix_sshd_option "PermitRootLogin" "no"; then
            changed=true
        fi
        fi

        emit_result "$id" "SSH root login is disabled" "high" "fail" \
        "permitrootlogin $value" \
        "Set PermitRootLogin no, validate sshd with sshd -t, then reload sshd." \
        true "$changed"
        ;;
    esac
    
}