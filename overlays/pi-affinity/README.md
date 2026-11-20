# Pi affinity (`pia`)

`pkgs.pi-affinity` is an opt-in variant of the pinned `llm-agents` Pi package.
It installs **`pia`**, not `pi`, so both packages can coexist. The personal-tools
Home Manager profile includes both. Activate your normal host configuration to
put `pia` on PATH; adding this package does not replace `~/.local/bin/pi-affinity`.

## Behavior

The patch preserves explicit Codex `session-id` headers for both SSE and WebSocket
handshakes. Without an explicit header, normal per-session routing is unchanged.
It does not change child session IDs, `x-client-request-id`, body
`prompt_cache_key`, or WebSocket cache/connection identity.

`pia` sets `PI_CODEX_AFFINITY_CORE=1`, enabling the existing extension at
`~/.pi/agent/extensions/codex-affinity/`. **That extension is still required for
root-session routing policy, commands, and measurements; it is not installed by
this package.** The core patch alone only respects caller-supplied headers.
Stock `pi` does not opt in to the extension.

Use `/codex-affinity status`, `/codex-affinity on`, `/codex-affinity off`, and
`/codex-affinity report` as before. Restart sessions and launch new children after
switching executables or routing mode; established WebSocket connections retain
their handshake. Shared routing does not guarantee cache hits or token savings.

The package retains a matching patched npm SDK under
`$out/libexec/pi-affinity-sdk`. Its wrapper sets:

- `PI_SUBAGENTS_PI_CODING_AGENT_PACKAGE_ROOT` to that SDK;
- `PI_SUBAGENT_PI_BINARY` to `$out/bin/pia`.

The standalone runtime lives under `$out/libexec/pi-affinity`, separate from
stock Pi's `$out/libexec/pi`, so Home Manager can merge both packages without
file collisions. The wrapper, Darwin signing hook, and native-module install
check all use the namespaced runtime path.

It preserves the upstream wrapper's runtime assets (`PI_PACKAGE_DIR`), PATH,
telemetry settings, and binary-signing hooks. No runtime path points into the
local experiment checkout or a particular user's home directory. Children that
intentionally disable extensions and unrelated external runners do not acquire
the extension's routing policy.

## Implementation and upgrades

The upstream Nix recipe consumes already-built npm JavaScript, not the source
checkout. `codex-routing.patch` is the JavaScript equivalent of the experiment's
two-location TypeScript patch. It is applied to `pi-ai` in `postConfigure`, after
npm installs dependencies and before Bun compiles the standalone executable.
The installed SDK retains the same patched dependency.

The patch uses zero fuzz, and `test-routing.cjs` runs during each build against
the actual patched header builders. Tests cover both transports, explicit
routing, normal fallback, case-insensitive headers, model/default headers,
removal of a default header, and independent request IDs. Upstream changes may
require refreshing or retiring the patch; review both transports when updating
`llm-agents` rather than blindly carrying it forward.

Build only this package from the repository root (also works before new files
have been staged, because the overlay is imported from the working tree):

```sh
nix build --no-link --print-out-paths --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    pkgs = import f.inputs.nixpkgs {
      system = builtins.currentSystem;
      overlays = import ./overlays (f.inputs // { inputs = f.inputs; });
    };
  in pkgs.pi-affinity
'
```

Run `<printed-store-path>/bin/pia --version` or start it directly before activating
Home Manager. For normal Git-flake host builds, ensure these new files are
tracked first.

## Initial validation

Validated on aarch64-darwin with Pi 1.5.2:

- Nix build, build-time SSE/WebSocket tests, and upstream install checks passed.
- A combined `buildEnv` with stock Pi and pi-affinity passed, as did the actual
  Rhodium Home Manager path build (without activating the configuration):
  `nix build --no-link '.#darwinConfigurations."rhodium@aarch64-darwin".config.home-manager.users.edattore.home.path'`.
  Both `pi` and `pia` in that merged environment returned `1.5.2`, and the mock
  CLI comparisons also passed through the merged environment's `pia`.
- `pia --version` returned `1.5.2`; stock `pi` was not replaced.
- Local mock-provider CLI comparisons passed for stock/on/off, including
  extension package-metadata resolution, child request identity, body cache key,
  and usage measurements (using the existing experiment's `verify-cli.mjs`).
- The retained SDK imported successfully and resolved through pi-subagents'
  native-child peer-alias loader.

No real provider requests were used for these checks. Linux builds have not
been validated locally.
