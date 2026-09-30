# NixOS configuration

This is the Linux-specific layer for `indium@x86_64-linux`. Its current hardware and desktop settings live in `hosts/nixos/indium.nix`, with host identity read from `hosts/inventory.toml`. Do not assume the Indium system module or Disko device layout suits another machine.

## Layout

```text
.
├── config/login-wallpaper.png  # Display-manager asset
├── disk-config.nix             # disko disk layout
├── files.nix                   # Linux-only Home Manager files
├── home-manager.nix            # Linux Home Manager additions
├── packages.nix                # Linux-only packages
└── secrets.nix                 # sops-nix declarations
```

`disk-config.nix` is hardware-specific and destructive; review the device before using it for installation or recovery. The NixOS Home Manager layer imports the shared user configuration, while standalone Home Manager uses `modules/home-manager` directly.
