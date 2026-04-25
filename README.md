# Eric's Nix(OS|-darwin) configuration

## TODOs:
- [x] Support multiple hosts
    - [X] Change `flake.nix` to have separate hosts
    - [X] Patch the `apps/*` scripts to take an argument for the host
    - [ ] Build work and personal nix-darwin/macOS hosts
    - [ ] Build a NixOS host for Framework 13
    - [ ] Build a NixOS host for WSL
    - [ ] Build a NixOS host for a Linux VM
- [x] Secrets managed with `sops-nix`
- [ ] Convert Neovim configuration into a Nix-Lazy hybrid
- [ ] Separate out `home-manager` and OS configurations
- [ ] Add separate `home-manager` checks

## Secrets

- Secrets now live in `/Users/edattore/workspace/nix/nix-secrets` as `sops` YAML files.
- Use `shared/common.yaml` only for secrets genuinely consumed by more than one host.
- Keep per-host secrets in `hosts/<hostname>.yaml`.
- Each host decrypts with a local key at `/var/lib/sops-nix/key.txt`.
- Edit secrets with your YubiKey-backed GPG identity via `sops`.
