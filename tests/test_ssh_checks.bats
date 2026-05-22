#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  mkdir -p "$BATS_TEST_TMPDIR/bin"

  cat > "$BATS_TEST_TMPDIR/bin/sshd" <<'FAKE_SSHD'
#!/usr/bin/env bash
if [[ "$*" == *"-T"* ]]; then
  printf 'permitrootlogin yes\npasswordauthentication yes\n'
  exit 0
fi

if [[ "$*" == *"-t"* ]]; then
  exit 0
fi
FAKE_SSHD

  chmod +x "$BATS_TEST_TMPDIR/bin/sshd"
}

@test "SSH root login check fails when effective config allows root" {
  run bash "$PROJECT_ROOT/harden-audit.sh" --check SSH-001 --format json
  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.results[0].id == "SSH-001"'
  echo "$output" | jq -e '.results[0].status == "fail"'
}
