# Eric's Nix(OS|-darwin) configuration

## TODOs:
- [x] Support multiple hosts
    - [X] Change `flake.nix` to have separate hosts
    - [X] Patch the `apps/*` scripts to take an argument for the host
    - [ ] Build work and personal nix-darwin/macOS hosts
    - [ ] Build a NixOS host for Framework 13
    - [ ] Build a NixOS host for WSL
    - [ ] Build a NixOS host for a Linux VM
- [ ] Migrate to `sops-nix` from `agenix`
- [ ] Convert Neovim configuration into a Nix-Lazy hybrid
- [ ] Separate out `home-manager` and OS configurations
    - [ ] Add separate `home-manager` checks
