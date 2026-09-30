# Shared configuration

This directory contains configuration used by both full host configurations and the standalone Home Manager output.

## Layout

```text
.
├── config/           # Source assets and the editable Neovim/Ghostty trees
├── default.nix       # Shared system options and fonts
├── files.nix         # Nix-managed shared files
├── home-manager.nix  # Shared user programs and shell configuration
└── packages.nix      # Packages common to both platforms
```

Most files declared here are generated as immutable Nix-store links. Edit the source in the checkout and activate a new generation. The optional `-editable` standalone Home Manager outputs instead link Neovim and Ghostty config to `~/.nixos-config/modules/shared/config/...` for live editing; see the root README.
