#!/usr/bin/env bash

load_profile() {
  local profile="$1"
  local profile_file="$BASE_DIR/profiles/$profile.conf"

  [[ -f "$profile_file" ]] || err "profile not found: $profile"
  source "$profile_file"
}
