#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT"
cp flake.lock "$TEMP_DIR/flake.lock.before"

# Selecting the Darwin app must not force Rhodium's opt-in secrets input: nix run
# evaluates the app before its script can add an input override to the build.
app_program="$(nix eval --accept-flake-config --no-write-lock-file --raw '.#apps.aarch64-darwin.build.program')"
[[ "$app_program" == /nix/store/*/bin/build ]]

# The actual opted-in host still requires its configured file at evaluation time.
if nix eval --accept-flake-config --no-write-lock-file --raw \
  '.#darwinConfigurations."rhodium@aarch64-darwin".config.system.build.toplevel.drvPath' \
  >"$TEMP_DIR/rhodium.out" 2>"$TEMP_DIR/rhodium.err"; then
  echo 'Rhodium unexpectedly evaluated without its opted-in secrets file' >&2
  exit 1
fi
grep -Fq 'Host rhodium needs a valid secrets repo/file and an overridden input containing that file' \
  "$TEMP_DIR/rhodium.err"

# A temporary empty file is sufficient to exercise the path validation. This
# only evaluates the derivation; it does not build, decrypt, or activate it.
mkdir -p "$TEMP_DIR/personal-secrets/hosts"
: > "$TEMP_DIR/personal-secrets/hosts/rhodium.yaml"
rhodium_drv="$(nix eval --accept-flake-config --no-write-lock-file \
  --override-input personal-secrets "path:$TEMP_DIR/personal-secrets" \
  --raw '.#darwinConfigurations."rhodium@aarch64-darwin".config.system.build.toplevel.drvPath')"
[[ "$rhodium_drv" == /nix/store/*.drv ]]

# An unrelated host remains evaluable with the default empty secrets inputs.
indium_drv="$(nix eval --accept-flake-config --no-write-lock-file --raw \
  '.#nixosConfigurations."indium@x86_64-linux".config.system.build.toplevel.drvPath')"
[[ "$indium_drv" == /nix/store/*.drv ]]

cmp -s "$TEMP_DIR/flake.lock.before" flake.lock
printf 'Rhodium bootstrap evaluation tests passed\n'
