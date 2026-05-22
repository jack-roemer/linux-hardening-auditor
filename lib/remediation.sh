#!/usr/bin/env bash

require_root_for_fix() {
  if [[ "$FIX" -eq 1 ]] && ! is_root; then
    echo "--fix requires root" >&2
    exit 4
  fi
}

backup_file() {
  local file="$1"

  [[ -z "$BACKUP_DIR" ]] && return 0
  [[ -e "$file" ]] || return 0

  local rel="${file#/}"
  local dest="$BACKUP_DIR/$rel.$(date -u +%Y%m%dT%H%M%SZ)"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] backup $file -> $dest" >&2
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  cp -a -- "$file" "$dest"
}

apply_cmd() {
  local description="$1"
  shift

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $description: $*" >&2
    return 0
  fi

  "$@"
}

ensure_kv_line() {
  local file="$1"
  local key="$2"
  local value="$3"

  backup_file "$file"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] ensure $key $value in $file" >&2
    return 0
  fi

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if grep -Eq "^[[:space:]]*#?[[:space:]]*$key[[:space:]]+" "$file"; then
    sed -i.bak -E "s|^[[:space:]]*#?[[:space:]]*$key[[:space:]].*|$key $value|" "$file"
    rm -f "$file.bak"
  else
    printf '%s %s\n' "$key" "$value" >> "$file"
  fi
}
