#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/apps/personal-secrets.sh"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
HOME="$TEMP_DIR/home"
mkdir -p "$HOME/workspace/nix/nix-secrets"

CAPTURED=()
capture() {
  CAPTURED=("$@")
}

assert_args() {
  local expected actual
  expected="$(printf '%s\n' "$@")"
  actual="$(printf '%s\n' "${CAPTURED[@]}")"
  if [[ "$actual" != "$expected" ]]; then
    printf 'Expected arguments:\n%s\nActual arguments:\n%s\n' "$expected" "$actual" >&2
    exit 1
  fi
}

unset PERSONAL_SECRETS_PATH
run_with_personal_secrets rhodium capture nix build '.#rhodium'
assert_args nix build '.#rhodium' \
  --override-input personal-secrets "path:$HOME/workspace/nix/nix-secrets" \
  --no-write-lock-file

PERSONAL_SECRETS_PATH="$TEMP_DIR/custom secrets"
mkdir -p "$PERSONAL_SECRETS_PATH"
run_with_personal_secrets rhodium capture nix flake check
assert_args nix flake check \
  --override-input personal-secrets "path:$PERSONAL_SECRETS_PATH" \
  --no-write-lock-file

run_with_personal_secrets rhodium capture nix build \
  --override-input personal-secrets path:/explicit/secrets '.#rhodium'
assert_args nix build \
  --override-input personal-secrets path:/explicit/secrets '.#rhodium' \
  --no-write-lock-file

run_with_personal_secrets rhodium capture nix build \
  --override-input=personal-secrets path:/explicit/secrets '.#rhodium'
assert_args nix build \
  --override-input=personal-secrets path:/explicit/secrets '.#rhodium' \
  --no-write-lock-file

run_with_personal_secrets indium capture nix build '.#indium'
assert_args nix build '.#indium'

run_with_personal_secrets work-mbp capture nix build '.#work-mbp'
assert_args nix build '.#work-mbp'

printf 'personal-secrets wrapper tests passed\n'
