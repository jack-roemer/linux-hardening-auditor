#!/usr/bin/env bash

PROFILE="baseline"
FORMAT="table"
FIX=0
DRY_RUN=0
BACKUP_DIR=""
CHECK_FILTER=""
HK_ROOT="${HK_ROOT:-}"

usage() {
  cat <<'EOF'
Usage:
  ./harden-audit.sh [options]

Options:
  --profile NAME        Profile name. Default: baseline
  --format FORMAT       json, markdown, or table. Default: table
  --fix                 Apply available remediations
  --dry-run             Show intended changes without applying them
  --backup DIR          Backup modified files before remediation
  --check ID            Run a single check ID
  --root DIR            Test-only root prefix for fixtures
  -h, --help            Show help
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --profile) PROFILE="${2:?missing profile}"; shift 2 ;;
      --format) FORMAT="${2:?missing format}"; shift 2 ;;
      --fix) FIX=1; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --backup) BACKUP_DIR="${2:?missing backup dir}"; shift 2 ;;
      --check) CHECK_FILTER="${2:?missing check id}"; shift 2 ;;
      --root) HK_ROOT="${2:?missing root dir}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
  done

  case "$FORMAT" in
    json|markdown|table) ;;
    *) echo "Invalid format: $FORMAT" >&2; exit 2 ;;
  esac
}