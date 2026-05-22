#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
}

@test "json output contains tool metadata" {
  mkdir -p "$BATS_TEST_TMPDIR/root/etc"
  printf 'UMASK 027\nUID_MIN 1000\n' > "$BATS_TEST_TMPDIR/root/etc/login.defs"
  printf 'root:x:0:0:root:/root:/bin/bash\n' > "$BATS_TEST_TMPDIR/root/etc/passwd"

  run bash "$PROJECT_ROOT/harden-audit.sh" --format json --root "$BATS_TEST_TMPDIR/root"
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  echo "$output" | jq -e '.tool == "hardenkit"'
  echo "$output" | jq -e '.profile == "baseline"'
  echo "$output" | jq -e '.results | type == "array"'
}
