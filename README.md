# Eric's Nix configuration

This flake manages one macOS host, one NixOS host, and standalone Home Manager configurations.

## Supported outputs

| Output | Use |
| --- | --- |
| `rhodium@aarch64-darwin` | Full nix-darwin system for Rhodium |
| `indium@x86_64-linux` | Full NixOS system for Indium |
| `edattore@aarch64-darwin` | Standalone Home Manager on macOS |
| `edattore@x86_64-linux` | Standalone Home Manager on Linux |
| `edattore-editable@aarch64-darwin` | Standalone Home Manager with editable links on macOS |
| `edattore-editable@x86_64-linux` | Standalone Home Manager with editable links on Linux |

The full host outputs include Home Manager. Use a standalone output when only the user environment is managed on a host outside this flake. The default outputs use store-backed files; the `-editable` outputs require the checkout at `~/.nixos-config`. Host-qualified standalone outputs such as `edattore@rhodium-aarch64-darwin` are generated from the inventory; the shorter names above remain aliases for the existing machines.

## Hosts and profiles

`hosts/inventory.toml` declares each machine's platform, system, username, hostname, home directory, state version, and profiles. `[users.<name>]` contains shared user data. The flake generates host outputs, host-qualified Home Manager outputs, apps, and checks from these records. `hosts/darwin/default.nix` contains minimal macOS defaults; `hosts/darwin/rhodium.nix` holds Rhodium's caches and preferences, while `hosts/nixos/indium.nix` holds Indium's disk, boot, SSH, desktop, and service policy. Register a new machine-specific module in `hostModules` in `flake.nix` when needed; every NixOS host requires one. Profile names map to Nix modules there too. `personal` enables Rhodium's Homebrew apps, MAS apps, Dock, personal tools, and optional sops declarations; `desktop` keeps Indium's personal tools; `work` adds only the known Python/TypeScript/Go toolchain. `development` adds that same stack and `just` to Home Manager. Rhodium and Indium select `development` to retain their previous language tools.

To create a profile, add a module such as `modules/profiles/home/work.nix`:

```nix
{ pkgs, ... }: {
  home.packages = [ pkgs.k9s ];
}
```

Extend `modules/profiles/home/work.nix` as requirements become known. For a *new* profile name, add another entry to `profileModules` with `darwin`, `nixos`, and `home` module lists. System settings go in the corresponding `darwin` or `nixos` list. Select profiles with `profiles = ["work"]` on a host in `hosts/inventory.toml`. Unknown profile names fail evaluation. Shared Home Manager shell and general utilities still apply on all hosts; review them against work device policy.

For a new **Apple Silicon work MacBook**, add a record like this to `hosts/inventory.toml` (the `edattore` user already exists):

```toml
[hosts.work-mbp]
platform = "darwin"
system = "aarch64-darwin"
username = "edattore"
hostname = "WorkMBP"
homeDirectory = "/Users/edattore"
stateVersion = 7  # Set this to the version used when this Mac first joins nix-darwin.
email = "eric@company.example"  # Optional override of [users.edattore].email.
profiles = ["work"]
```

Set a real work `email` before evaluating: work hosts must not inherit the personal Git identity. Without `personal`, the work host does not get Rhodium's Homebrew casks, MAS apps, Dock, personal tools, personal Git signing key, caches, or personal secret declarations. It still inherits shared Home Manager utilities and a minimal Darwin baseline. Review those, the Python/TypeScript/Go versions, and your employer's device policy before switching. Confirm the account home directory, host name, and state version too. For another macOS user, first add `[users.<username>]` with `name`, `email`, and `homeStateVersion`. The work output is not present until you add a host record.

After adding the record, stage `hosts/inventory.toml` and any new profile modules so the Git flake can see them. Run `nix flake check --all-systems --no-build`, then build and switch with:

```sh
nix build '.#checks.aarch64-darwin.work-mbp' --no-link
nix build '.#checks.aarch64-darwin.edattore-work-mbp-home' --no-link
sudo darwin-rebuild switch --flake '.#work-mbp@aarch64-darwin'
# Standalone Home Manager instead of a full system switch:
home-manager switch --flake '.#edattore@work-mbp-aarch64-darwin'
```

The flake checks include each new host under its inventory key. Work host outputs were evaluated with a temporary sample record, but no work machine is configured or built in the committed inventory.

## Optional, separate secrets repositories

The tracked `personal-secrets` and `work-secrets` flake inputs both point to `secrets/empty` (no SSH fetch). No host opts in by default. To enable one for a host, add its own inventory table, for example:

```toml
[hosts.rhodium.secrets]
repo = "personal"
file = "hosts/rhodium.yaml"
```

Then supply **only** that input when evaluating/building, e.g. `nix flake check --no-build --no-write-lock-file --override-input personal-secrets 'git+ssh://git@github.com/ELD/nix-secrets.git'`. Use `work-secrets` and `repo = "work"` for a work host, with its own repository, ciphertext file, key policy, and SOPS declarations. The work profile defaults to a separate `/var/lib/sops-nix/work-key.txt`; confirm its location and recipients with your employer before enabling secrets. The configured profile must match the repo; a missing file is an evaluation error. Rhodium's `modules/darwin/secrets.nix` declares its existing personal keys when opted in; the work module only provides a SOPS default file, **not** invented employer secret names. Do not commit override URLs or private revisions to `flake.lock` (use `--no-write-lock-file`); never put plaintext credentials in this flake.

These slots separate input contents and prevent an unconditional personal fetch, but are not a hard security boundary if you override both in one invocation. For strict isolation use separate wrapper flakes/accounts and distinct decryption keys. The sigmavim checkout submodule has a separate SSH dependency.

## Build, check, and switch

Run these from the checkout (only the optional `-editable` outputs require it at `~/.nixos-config`):

```sh
nix develop                         # development tools
nix flake check                     # evaluation and build checks

nix build '.#darwinConfigurations."rhodium@aarch64-darwin".system'
nix build '.#nixosConfigurations."indium@x86_64-linux".config.system.build.toplevel'
nix build '.#homeConfigurations."edattore@aarch64-darwin".activationPackage'
nix build '.#homeConfigurations."edattore@x86_64-linux".activationPackage'
```

Switch a full host with its native tool:

```sh
sudo darwin-rebuild switch --flake '.#rhodium@aarch64-darwin'
sudo nixos-rebuild switch --flake '.#indium@x86_64-linux'
```

For standalone Home Manager, install/use the Home Manager CLI and run the output for your platform:

```sh
home-manager switch --flake '.#edattore@aarch64-darwin' # store-backed
home-manager switch --flake '.#edattore@x86_64-linux'   # store-backed
# For live-editable Neovim/Ghostty files, clone at ~/.nixos-config and use:
home-manager switch --flake '.#edattore-editable@aarch64-darwin'
home-manager switch --flake '.#edattore-editable@x86_64-linux'
```

CI runs `nix flake check` on Linux and macOS. The flake also exposes a `formatter` (`nix fmt flake.nix`) and checks for nixfmt, deadnix, statix, Actionlint, and ShellCheck. ShellCheck currently treats errors as failures; warnings in older scripts remain to be cleaned up. The update workflow uses `nix flake check --all-systems --no-build --no-write-lock-file` as an evaluation-only lock-file preflight.

## Editable and immutable files

By default, Home Manager files come from the flake source in the Nix store. Edit this repository and activate a new generation; do not edit generated files in `~/.config`.

The `-editable` outputs set `local.editableConfigRoot` to `~/.nixos-config`. With those outputs, `~/.config/nvim`, `~/.config/ghostty/config`, and `~/.config/ghostty/themes` point into the checkout and can be edited live. For a different checkout location, change `local.editableConfigRoot` in an `extraModules` entry for your own Home Manager output. Full host configurations use the store-backed default unless you set the option for their Home Manager user too.

Neovim is a submodule, so commit changes there separately. Git flakes omit submodule contents by default, so the store-backed output uses a separate `sigmavim` flake input pinned to the submodule's commit. When updating the submodule, update that revision in `flake.nix` and regenerate `flake.lock` too. The store-backed source filters out its tracked README symlink to a local Nix-store generation. Ghostty shaders come from a pinned flake input in both modes.

SSH agent forwarding is off by default. For a host that needs it, use `ssh -A host` for that connection or add a named `Host` entry with `ForwardAgent yes` in `~/.ssh/config_external`. Do not enable it for `Host *`.

## Bootstrap and recovery

There is no supported one-command installer. The old `apply` scripts were removed because they rewrote files indiscriminately and expected an obsolete flake layout. For a new or recovered machine:

1. Install Nix with flakes enabled, then clone this repository with its submodules, for example:
   `git clone --recurse-submodules git@github.com:ELD/nixos-config.git ~/.nixos-config`. Choose any location for store-backed Home Manager outputs; the `-editable` outputs use `~/.nixos-config`.
2. If enabling personal secrets, confirm SSH access to the personal secrets repository and initialize the YubiKey/GPG and sops setup. A default build needs no secrets-repo access.
3. Only when opting into personal secrets, restore `/var/lib/sops-nix/key.txt` before activating the host; work defaults to a different key file (see above). Indium currently declares no sops secrets.
4. Run `nix flake check`, build the target, and then use the native switch command above.

For a fresh NixOS install, `modules/nixos/disk-config.nix` still contains `/dev/%DISK%`. Replace that placeholder with the intended device (prefer `/dev/disk/by-id/...`) and review the partition layout before building or using disko. Disko **erases the selected disk**. The host configuration is specific to Indium; do not run it against another machine without reviewing its hardware and boot settings. A repeatable `nixos-anywhere` installer is a future task, not a working command yet. For a bad generation, keep the previous generation and use `darwin-rebuild switch --rollback`, `nixos-rebuild switch --rollback`, or the Home Manager generation list/rollback commands. Restore SSH and sops access before attempting another switch.

## CI credentials and updates

- `GHA_DK` is an SSH private key used by Actions checkout for the sigmavim submodule. Default flake checks do not access a secrets repository. Grant it read-only access; GitHub deploy keys cannot be shared between repositories. Eric alone rotates this key by adding a replacement public key, updating the Actions secret, verifying CI, and revoking the old key. Never commit the private key.
- `REPO_ACCESS_TOKEN` is a fine-grained token for the update workflow to push its branch and open/label a PR. Grant repository Contents, Pull requests, and Issues read/write access. It is separate from `GITHUB_TOKEN` so the resulting PR can run checks.

Checks run for pushes and pull requests on Linux and macOS. Scheduled input updates run Monday (core), Wednesday (Homebrew), and Friday (developer tools); the same groups can be selected with `workflow_dispatch`. The updater tests each new lock file before opening an independent PR. If two PRs change `flake.lock`, re-run or rebase the second after the first merges.
