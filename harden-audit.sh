#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$BASE_DIR/lib/common.sh"
source "$BASE_DIR/lib/cli.sh"
source "$BASE_DIR/lib/profiles.sh"
source "$BASE_DIR/lib/output.sh"
source "$BASE_DIR/lib/remediation.sh"

parse_args "$@"
load_profile "$PROFILE"

RESULTS_FILE="$(mktemp)"
trap 'rm -f "$RESULTS_FILE"' EXIT

load_checks() {
  local check

  for check in "$BASE_DIR"/checks/*.sh; do
    source "$check"
  done
}

run_checks() {
  check_ssh_root_login
  check_ssh_password_auth
  check_sudoers_permissions
  check_inactive_users
  check_world_writable_dirs
  check_firewall
  check_umask
  check_docker_socket
  check_cron_permissions
}

load_checks
run_checks
render_output "$FORMAT"
exit_with_audit_status
