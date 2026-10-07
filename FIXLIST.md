# Fix list

Review scope: the `home-manager-refactor` branch plus staged and unstaged work. I ignored changes inside submodules.

## Must fix before merge

- [x] **Finish the Ghostty file repairs.**

  The files are repaired and the stale `ghostty-shaders` submodule declaration has been removed from `.gitmodules` (staged; commit before merge). The flake input remains the only source.

  Check the result with:

  ```sh
  git ls-tree -r HEAD modules/shared/config/ghostty
  find modules/shared/config/ghostty -type l \
    -exec sh -c 'printf "%s -> %s\n" "$1" "$(readlink "$1")"' _ {} \;
  ```

- [x] **Fix private submodule checkout in `.github/workflows/check.yml`.**

  `.github/workflows/check.yml` now passes `GHA_DK` as `ssh-key` to `actions/checkout` for submodule checkout. Confirm it works on a fresh runner.

- [x] **Split the two Darwin hosts properly, or remove `eric.dattore-mac`.**

  `eric.dattore-mac` was removed; only Rhodium remains as a Darwin host.

- [x] **Commit and test one coherent tree.**

  The original refactor fixes landed in `da2dfdf` and its preceding commits. The workflow and documentation updates landed in `2995fb0`. Run the checks below against the latest commit before merging.

## Input updates and GitHub Actions

- [x] **Make Home Manager follow the root Nixpkgs input.**

  ```nix
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ```

  Regenerate `flake.lock` afterward. Confirm that Home Manager no longer brings in its own Nixpkgs node.

- [x] **Document access to the private `secrets` input.**

  `README.md` describes `GHA_DK` access to `ELD/nix-secrets`, the read-only requirement, and rotation by Eric. Confirm the key is actually read-only in the repository settings.

- [x] **Remove the second SSH-agent step from `.github/workflows/update.yml`.**

  The update workflow uses one SSH-key checkout.

- [x] **Set explicit permissions on the update workflow.**

  The workflow grants `GITHUB_TOKEN` read-only contents access and uses `REPO_ACCESS_TOKEN` to push and open PRs. `README.md` documents the token's required repository permissions; verify its actual scopes in GitHub.

- [x] **Add workflow concurrency rules.**

  Update jobs queue rather than interrupt one another; check jobs cancel superseded runs for the same branch.

- [ ] **Verify the updated lock file on a real update PR.**

  The update workflow now runs `nix flake check --all-systems --no-build --no-write-lock-file` after updating the selected inputs and before opening a PR. Trigger a group update and confirm that gate passes and the PR check workflow runs. Native Linux and Darwin builds should cover their own system closures when runners are available. The gate has not yet been tested against a newly updated lock file.

- [x] **Run CI on pull requests.**

  Add a `pull_request` trigger rather than depending on a `push` event created by a particular token.

- [x] **Decide how to maintain the `nix-homebrew` fork.**

  The input now follows upstream `github:zhaofengli/nix-homebrew` rather than the fork.

- [x] **Reduce lock-file update noise.**

  Core Nix inputs, Homebrew repositories, and developer-tool inputs now update on separate weekly schedules (or by manual group selection). Each group opens an independent PR against `main`; re-run or rebase another open update PR if their `flake.lock` changes conflict.

## Configuration and portability

- [x] **Remove the fixed `~/.nixos-config` assumption from standalone Home Manager.**

  Default standalone outputs now use store-backed files; explicitly named `-editable` outputs set `local.editableConfigRoot` for live links into `~/.nixos-config`. The pinned `sigmavim` input supplies submodule content to the store-backed output. Keep its revision aligned with the submodule gitlink.

- [x] **Keep host and user data in one place.**

  `hosts/inventory.toml` declares Rhodium and Indium, their users and profiles. The flake generates system, Home Manager, app, and check outputs from the records. Rhodium's personal Homebrew, MAS, Dock, and secrets setup is isolated behind the `personal` profile. Machine-specific hardware and the remaining shared package list still need review before adding a new host.

- [ ] **Narrow the permissive Nixpkgs settings.**

  Review these global settings:

  - `allowBroken = true`
  - `allowUnsupportedSystem = true`
  - `permittedInsecurePackages = [ "olm-3.2.16" ]`

  Keep each exception only where it is needed, and leave a comment explaining why.

- [x] **Stop forwarding the SSH agent to every host.**

  The wildcard default is now `ForwardAgent = false`. Use `ssh -A` for an individual connection or add a named host to `~/.ssh/config_external` when forwarding is needed.

- [x] **Repair or remove the old `apply` scripts.**

  The scripts and their flake app entries were removed. A safe, repeatable bootstrap for new NixOS machines remains follow-up work.

- [x] **Resolve the incomplete `aarch64-linux` support.**

  Removed the unsupported apps and development shell from flake outputs, the legacy app symlink, and stale references in Linux scripts.

- [ ] **Separate the shared package list into smaller groups.**

  The duplicate `devenv` entry was removed (staged). Consider package groups for personal, work, desktop, and development machines rather than installing the full list everywhere.

- [x] **Explain or remove temporary overlays.**

  `overlays/40-highlight.nix` was removed instead of documenting a patch-clearing override (staged).

## Formatting and repository cleanup

- [x] **Format the Nix files.**

  The previously failing Nix files now pass `nixfmt --check`.

- [x] **Fix the whitespace in `modules/nixos/files.nix`.**

  The embedded power-menu script was retabbed; `git diff --check main` passes.

- [x] **Review the `deadnix` warnings.**

  The unused arguments and bindings were cleaned up; `deadnix --fail .` passes.

- [x] **Fix the `statix` warning in `modules/darwin/dock/default.nix`.**

  The `local.dock.*` options now share one attribute set; `statix check .` passes.

- [x] **Run formatting and linting through the flake.**

  Added a `formatter` output and flake checks for nixfmt, deadnix, statix, ShellCheck (errors only for now), and Actionlint on both supported systems. CI's `nix flake check` runs the checks. JSON/TOML/KDL formatting and a pre-commit hook remain optional follow-ups.

- [x] **Add `.gitignore` and remove local environment files from Git.**

  `.direnv/` and `result/` are ignored, and the tracked `.direnv/flake-profile*` links have been staged for removal. Add Home Manager backup patterns later if they appear locally; commit the staged cleanup before merge.

- [x] **Bring the documentation up to date.**

  Updated `README.md` and the module READMEs for supported outputs, checks, editable links, CI credentials, recovery, and the limits of the current bootstrap. The checkout-root setting and a fresh NixOS installer remain separate open tasks.

- [x] **Decide whether to pin GitHub Actions to commit SHAs.**

  Decided to keep version tags; no SHA-pinning policy for this repository.

## Useful follow-up work

These are larger improvements, not merge blockers.

- [x] **Build host outputs from an inventory and reusable profiles.**

  Inventory-backed outputs and explicit profile module lists are implemented. `personal` retains Rhodium's configuration; `development` adds a Home Manager package. `work` and `desktop` are placeholders for future host-specific settings. Review the shared package list before using the work profile on an employer-managed machine.

- [ ] **Add one quality-check entry point.**

  `treefmt-nix` or a similar setup can provide formatting, linting, pre-commit hooks, and CI checks from the same configuration. Include native builds and binary-cache use where practical.

- [ ] **Add supported installation and deployment tools.**

  Candidates include:

  - `nixos-anywhere` with Disko for new Linux installs
  - `deploy-rs` or Colmena for remote deployment
  - A Darwin bootstrap command
  - Remote builders and binary-cache publishing

## Before asking for another review

Run these commands and keep the results:

```sh
git status --short --ignore-submodules=all
git diff --check main
find . -name '*.nix' -not -path './.git/*' -print0 | xargs -0 nixfmt --check
deadnix --fail .
statix check .
nix flake metadata --no-write-lock-file
nix flake show --all-systems --no-write-lock-file
nix flake check --all-systems --no-build --no-write-lock-file
```

Build the native closures on both platforms where possible:

```sh
# Darwin
nix build '.#checks.aarch64-darwin.edattore-home' --no-link
nix build '.#checks.aarch64-darwin.rhodium' --no-link

# Linux
nix build '.#checks.x86_64-linux.edattore-home' --no-link
nix build '.#checks.x86_64-linux.indium' --no-link
```

When you request the next review, point to the commit that contains the fixes. List anything you chose to defer and why.
