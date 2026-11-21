#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/bin" "$TEMP_DIR/home/workspace/nix/nix-secrets" "$TEMP_DIR/work"
for command_name in nix sudo; do
  cat >"$TEMP_DIR/bin/$command_name" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$TEMP_DIR/bin/$command_name"
done

check_launcher_colors() {
  local launcher="$1"
  local output
  if ! output="$(
    cd "$TEMP_DIR/work"
    PATH="$TEMP_DIR/bin:$PATH" \
      HOME="$TEMP_DIR/home" \
      PERSONAL_SECRETS_PATH="$TEMP_DIR/home/workspace/nix/nix-secrets" \
      "$launcher" --host rhodium 2>&1
  )"; then
    printf 'Launcher failed: %s\n%s\n' "$launcher" "$output" >&2
    return 1
  fi

  if [[ "$output" != *$'\033['* || "$output" != *$'\033[0m'* ]]; then
    printf 'Expected ANSI color codes in %s output, got:\n%s\n' "$launcher" "$output" >&2
    return 1
  fi
  if [[ "$output" == *'\033['* ]]; then
    printf 'Found literal backslash escape text in %s output:\n%s\n' "$launcher" "$output" >&2
    return 1
  fi
}

check_launcher_colors "$ROOT/apps/aarch64-darwin/build"
check_launcher_colors "$ROOT/apps/aarch64-darwin/build-switch"
printf 'aarch64 Darwin launcher color tests passed\n'
