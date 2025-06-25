{ pkgs }:

with pkgs; [
  # Formatters and LSP tools
  nixfmt-rfc-style

  # Chat tools
  gomuks
  iamb

  # Encryption/decryption tools
  age
  age-plugin-yubikey
  gnupg

  # Go dev tools
  air

  # Nix tools
  attic-client
  cachix
  comma
  deadnix
  devenv
  statix
  yubikey-manager

  # JavaScript tools
  bun
  nodejs_latest
  nodePackages.pnpm
  yarn

  # Golang tools
  golangci-lint
  templ

  # Java tools
  jdk11

  # Lua
  luajit
  luajitPackages.luarocks

  # VM/Containers
  colima

  # CI/CD and Cloud
  circleci-cli
  cirrus-cli
  doctl
  flyctl
  terraform
  turso-cli

  # Rust tools
  bacon
  cargo-nextest
  # cargo-expand
  cargo-outdated
  cargo-shuttle
  cargo-sweep
  # cargo-vet
  cargo-wipe
  diesel-cli
  evcxr
  rustup
  sqlx-cli
  sccache

  # Python tools
  python3Full
  python3Packages.pip
  python3Packages.jupyter_core
  python3Packages.ipython
  python3Packages.ipykernel
  python3Packages.fonttools
  pylint
  pipenv

  # LaTeX/Typesetting
  tectonic
  typst
  texliveFull

  # General utilities
  ascii-image-converter
  chafa
  coreutils-full
  curl
  devenv
  du-dust
  fd
  ffmpeg
  findutils
  fontforge
  gawk
  git
  gnugrep
  gnused
  jq
  lazygit
  neofetch
  openssh
  pre-commit
  ranger
  ripgrep
  ripgrep-all
  tealdeer
  tree
  treefmt
  tree-sitter
  unzip
  wget
  yt-dlp
  yq
]
