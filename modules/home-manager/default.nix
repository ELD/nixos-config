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

in
{
  imports = [ "${inputs.azithro}/nix/home-manager.nix" ];

  options.local.editableConfigRoot = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "/Users/edattore/workspace/nix/nixos-config";
    description = "Checkout root for live-editable Ghostty links; null uses flake sources. Neovim uses programs.azithro.editableConfigPath independently.";
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

    programs =
      (import ../shared/home-manager.nix {
        inherit
          inputs
          config
          pkgs
          lib
          host
          ;
      })
      // {
        azithro = {
          enable = true;
          configSource = inputs.azithro;
        };
      };

    # NOTE: Disable these universally to avoid a warning
    manual.manpages.enable = false;

    xdg.configFile = {
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
