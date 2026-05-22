#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT = "$BATS_TEST_DIRNAME/.."
}

@test "json output contains tool metadata" {

  run "$PROJECT_ROOT/harden-audit.sh" --format json --root "$BATS_TEST_TMPDIR/root"
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  
  echo "$output" | jq -e '.tool == "hardenkit"'

}