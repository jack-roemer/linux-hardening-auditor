#!/usr/bin/env bats

setup() {

    export PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
    export ROOT="$BATS_TEST_TMPDIR/root"
    mkdir -p "$ROOT/etc"
    echo 'UMASK 022' > "$ROOT/etc/login.defs"
    
}

@test "umask remediation is idempotent" {

    run "$PROJECT_ROOT/harden-audit.sh" --check UMASK-001 --fix --root "$ROOT" --format json
    [ "$status" -eq 1 ] || [ "$status" -eq 0 ]
    grep -q '^UMASK 027$' "$ROOT/etc/login.defs"

    run "$PROJECT_ROOT/harden-audit.sh" --check UMASK-001 --fix --root "$ROOT" --format json
    [ "$status" -eq 0 ]
    [ "$(grep -c '^UMASK 027$' "$ROOT/etc/login.defs")" -eq 1 ]

}