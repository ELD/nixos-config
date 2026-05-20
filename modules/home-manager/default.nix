{
  config,
  pkgs,
  lib,
  inputs ? { },
  host ? { },
  ...
}:

let
  user = config.home.username;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  linuxFiles = import ../nixos/files.nix {
    inherit user;
    homeDirectory = config.home.homeDirectory;
  };
  editableRoot = config.local.editableConfigRoot;
  sourceFor =
    relative: source:
    if editableRoot == null then
      source
    else
      config.lib.file.mkOutOfStoreSymlink "${editableRoot}/${relative}";

  # Git flakes do not include submodule contents by default. Use the pinned input
  # for the portable config, excluding its README link to a local Nix store.
  nvimSource = builtins.path {
    path = inputs.sigmavim;
    name = "sigmavim";
    filter =
      path: type:
      let
        name = builtins.baseNameOf path;
      in
      type != "symlink" && name != ".git" && name != ".DS_Store" && !(lib.hasSuffix ".old.bak" name);
  };
in
{
  imports = [ ];

  options.local.editableConfigRoot = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "/Users/edattore/workspace/nix/nixos-config";
    description = "Checkout root for live-editable Neovim and Ghostty links; null uses flake sources.";
  };

  config = {
    home = {
      enableNixpkgsReleaseCheck = false;
      packages =
        if isDarwin then
          pkgs.callPackage ../darwin/packages.nix { }
        else if isLinux then
          pkgs.callPackage ../nixos/packages.nix { }
        else
          pkgs.callPackage ../shared/packages.nix { };
      file = sharedFiles // lib.optionalAttrs isLinux linuxFiles;
      sessionPath = lib.optionals isDarwin [
        "${config.home.homeDirectory}/.cargo/bin"
      ];
      stateVersion = host.homeStateVersion or "26.11";
    };

    programs = import ../shared/home-manager.nix {
      inherit
        inputs
        config
        pkgs
        lib
        host
        ;
    };

    # NOTE: Disable these universally to avoid a warning
    manual.manpages.enable = false;

    xdg.configFile = {
      nvim.source = sourceFor "modules/shared/config/sigmavim" nvimSource;
      "ghostty/config" = {
        source = sourceFor "modules/shared/config/ghostty/config" ../shared/config/ghostty/config;
        force = true;
      };
      "ghostty/themes" = {
        source = sourceFor "modules/shared/config/ghostty/themes" ../shared/config/ghostty/themes;
        force = true;
      };
      "ghostty/ghostty-shaders" = {
        source = inputs.ghostty-shaders;
        force = true;
      };
      "starship.toml" = {
        source = ../shared/config/starship.toml;
      };
      "tuicr/config.toml".source = ../shared/config/tuicr/config.toml;
      # "tuicr/config.toml".text = ''
      #   apperance = "system"
      #   theme_dark = "cendre"
      #   theme_light = "cendre-light"
      # '';
      "tuicr/themes/cendre-light.toml".source = ../shared/config/tuicr/themes/cendre-light.toml;
      "tuicr/themes/cendre.toml".source = ../shared/config/tuicr/themes/cendre.toml;
      "tuicr/themes/cendre.tmTheme".source = ../shared/config/tuicr/themes/cendre.tmTheme;
      "tuicr/themes/cendre-light.tmTheme".source = ../shared/config/tuicr/themes/cendre-light.tmTheme;
    };
  };
}
