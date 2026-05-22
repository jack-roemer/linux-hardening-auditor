#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
}

@test "help output includes usage" {
  run bash "$PROJECT_ROOT/harden-audit.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "invalid format returns CLI error" {
  run bash "$PROJECT_ROOT/harden-audit.sh" --format xml
  [ "$status" -eq 2 ]
}
