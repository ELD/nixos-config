{ pkgs }:

with pkgs;
[
  # Formatters and LSP tools
  nixfmt

  # Encryption/decryption tools
  age
  gnupg
  sops

  # Nix tools
  cachix
  comma
  deadnix
  devenv
  statix

  # VM/Containers
  # colima

  # Source hosting
  gh

  # General utilities
  ascii-image-converter
  chafa
  coreutils-full
  curl
  dust
  fastfetch
  fd
  ffmpeg
  findutils
  gawk
  git
  gnugrep
  gnused
  jq
  lazygit
  mdcat
  openssh
  openssl
  pkg-config
  prek
  ranger
  ripgrep
  ripgrep-all
  tealdeer
  # tmux
  tokei
  tree
  treefmt
  tree-sitter
  unzip
  wget
  yq

]
