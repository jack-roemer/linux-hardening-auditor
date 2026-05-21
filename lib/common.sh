#!/usr/bin/env bash

err() {

  echo "error: $*" >&2
  exit 1

}

command_exists() {

  command -v "$1" >/dev/null 2>&1 

}

is_root() {

  [[ "${EUID:-$(id -u)}" -eq 0 ]] # $(id -u) ensures compatibility in environments where EUID might not be set

}

hk_path() {

  local path="$1"

  [[ "$path" == /* ]] || err "hk_path requires an absolute path"

  if [[ -n "${HK_ROOT:-}" ]]; then
    printf '%s%s\n' "${HK_ROOT%/}" "$path"

  else
    printf '%s\n' "$path"
  fi

}

now_utc() {

  date -u +"%Y-%m-%dT%H:%M:%SZ"

}

should_run_check() {

  local id="$1"

  [[ -z "$CHECK_FILTER" || "$CHECK_FILTER" == "$id" ]]

}