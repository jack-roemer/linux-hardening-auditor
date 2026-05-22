#!/usr/bin/env bash

check_firewall() {
  local id="FW-001"
  should_run_check "$id" || return 0

  local evidence=""

  if command_exists ufw; then
    evidence="$(ufw status 2>/dev/null | head -n 1 || true)"
    if grep -qi "Status: active" <<< "$evidence"; then
      emit_result "$id" "Host firewall is active" "medium" "pass" \
        "$evidence" \
        "No action required." \
        false false
      return 0
    fi
  fi

  if command_exists firewall-cmd; then
    evidence="$(firewall-cmd --state 2>/dev/null || true)"
    if [[ "$evidence" == "running" ]]; then
      emit_result "$id" "Host firewall is active" "medium" "pass" \
        "firewalld running" \
        "No action required." \
        false false
      return 0
    fi
  fi

  if command_exists nft; then
    evidence="$(nft list ruleset 2>/dev/null | head -n 20 || true)"
    if [[ -n "$evidence" ]]; then
      emit_result "$id" "Host firewall ruleset exists" "medium" "warn" \
        "nft ruleset present; manual policy review required" \
        "Review default input policy and allowed services." \
        false false
      return 0
    fi
  fi

  emit_result "$id" "Host firewall is active" "medium" "fail" \
    "no active ufw/firewalld/nftables ruleset detected" \
    "Enable a host firewall only after confirming allowed management ports, especially SSH." \
    false false
}
