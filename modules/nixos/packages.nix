{
  pkgs,
  profile ? "full",
}:

with pkgs;
let
  inherit (pkgs) lib;
  isAarch64Linux = pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64;
  shared-packages = import ../shared/packages.nix { inherit pkgs profile; };
  vmPackages = [
    # Security and authentication
    keepassxc

    # Audio tools
    alsa-utils
    pulseaudio # pactl for PipeWire pulse compatibility
    pavucontrol

    # Wayland desktop tools
    chromium
    cliphist
    elephant
    ghostty
    grim
    hypridle
    hyprlock
    hyprpanel
    libnotify
    mako
    pcmanfm
    slurp
    walker
    wl-clipboard
    wlr-randr
    xdg-utils
  ];
  fullPackages = [

    # Security and authentication
    yubikey-agent
    keepassxc

    # App and package management
    appimage-run
    gnumake
    cmake
    home-manager

    # Media and design tools
    vlc
    fontconfig
    font-manager

    # Productivity tools
    bc # old school calculator
    # galculator

    # Audio tools
    alsa-utils
    cava # Terminal audio visualizer
    mpc
    pulseaudio # pactl for PipeWire pulse compatibility
    pavucontrol # Pulse audio controls

    # Testing and development tools
    direnv
    postgresql
    libtool # for Emacs vterm

    # Screenshot and recording tools
    grim
    slurp

    # Text and terminal utilities
    feh # Manage wallpapers
    ghostty
    tree
    unixtools.ifconfig
    unixtools.netstat
    wl-clipboard
    wlr-randr

    # File and system utilities
    inotify-tools # inotifywait, inotifywatch - For file system events
    cliphist
    elephant
    hypridle
    hyprlock
    hyprpanel
    libnotify
    mako
    pcmanfm # File browser
    sqlite
    walker
    xdg-utils

    # Other utilities
    (if isAarch64Linux then chromium else google-chrome)

    # PDF viewer
    zathura

  ]
  ++ lib.optionals (!isAarch64Linux) [
    # Music and entertainment
    spotify
  ];
in
shared-packages ++ (if profile == "vm" then vmPackages else fullPackages)
