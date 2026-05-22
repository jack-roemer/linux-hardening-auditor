#!/usr/bin/env bash

check_docker_socket() {
  
  local id="DOCKER-001"
  should_run_check "$id" || return 0

  local socket
  socket="$(hk_path /var/run/docker.sock)"

  local findings=()

  if [[ -S "$socket" || -e "$socket" ]]; then
    local mode owner group
    mode="$(stat -c '%a' "$socket" 2>/dev/null || echo unknown)"
    owner="$(stat -c '%U' "$socket" 2>/dev/null || echo unknown)"
    group="$(stat -c '%G' "$socket" 2>/dev/null || echo unknown)"

    if [[ "$mode" =~ [2367]$ ]]; then
      findings+=("docker.sock mode=$mode owner=$owner group=$group is world-accessible")
    fi
  fi

  if command_exists ss; then
    if ss -lntp 2>/dev/null | grep -E 'dockerd|docker' | grep -q ':2375'; then
      findings+=("Docker API appears to be listening on TCP port 2375")
    fi
  fi

  if command_exists docker; then
    local mounted
    mounted="$(
      docker ps -q 2>/dev/null |
        xargs -r docker inspect --format '{{.Name}} {{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}' 2>/dev/null |
        grep -F '/var/run/docker.sock' || true
    )"
    [[ -n "$mounted" ]] && findings+=("containers mounting docker.sock: $mounted")
  fi

  if ((${#findings[@]} == 0)); then
    emit_result "$id" "Docker socket is not broadly exposed" "critical" "pass" \
      "no broad docker socket exposure detected" \
      "No action required." \
      true false
    return 0
  fi

  local changed=false
  if [[ "$FIX" -eq 1 && -e "$socket" ]]; then
    require_root_for_fix
    apply_cmd "restrict docker socket mode" chmod 660 "$socket"
    changed=true
  fi

  emit_result "$id" "Docker socket is not broadly exposed" "critical" "fail" \
    "$(IFS='; '; echo "${findings[*]}")" \
    "Restrict socket permissions, avoid mounting docker.sock into containers, and secure any Docker TCP API with TLS." \
    true "$changed"

}
