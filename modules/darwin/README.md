# Darwin configuration

The minimal macOS baseline lives in `hosts/darwin/default.nix`. Rhodium's machine-specific preferences and caches live in `hosts/darwin/rhodium.nix`.

## Layout

```text
.
├── casks.nix        # Homebrew casks
├── dock/             # Declarative Dock entries
├── files.nix         # Darwin-specific Home Manager files
├── base-home-manager.nix  # User and Home Manager setup for every Darwin host
├── home-manager.nix       # Personal Homebrew, MAS, and Dock settings
├── packages.nix      # Darwin-only packages
└── secrets.nix       # sops-nix declarations for rhodium
```

`hosts/inventory.toml` supplies hostname, user, home directory, and profiles. Every Darwin host imports `base-home-manager.nix`; `personal` opts into Homebrew, MAS, Dock, and (only when explicitly configured) Rhodium personal secrets. `work` enables a separate optional SOPS source but declares no secrets yet. See the root README for adding a host and opting into a secrets repository.
