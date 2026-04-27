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

## Indium Secure Boot

Indium uses Lanzaboote with `sbctl` keys stored in `/var/lib/sbctl`.

Before switching the Lanzaboote system generation, verify the machine is booted with UEFI/systemd-boot and prepare Secure Boot keys:

```bash
bootctl status
sudo sbctl status
sudo sbctl create-keys
```

If `sbctl` is not available on the currently booted generation yet, run it through Nix:

```bash
nix shell nixpkgs#sbctl -c sudo sbctl status
nix shell nixpkgs#sbctl -c sudo sbctl create-keys
```

Enter Framework firmware setup and put Secure Boot into setup mode. Then enroll the generated keys:

```bash
sudo sbctl enroll-keys
```

Test the new generation before making it permanent:

```bash
sudo nixos-rebuild test --flake .#indium@x86_64-linux
sudo nixos-rebuild switch --flake .#indium@x86_64-linux
```

Keep recovery media available before enabling Secure Boot. If enrollment or boot fails, return to firmware setup and disable Secure Boot or reset keys.
