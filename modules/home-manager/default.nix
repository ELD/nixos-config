{
  config,
  pkgs,
  lib,
  inputs ? { },
  ...
}:

let
  user = "edattore";
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  linuxFiles = import ../nixos/files.nix {
    inherit user;
    homeDirectory = config.home.homeDirectory;
  };
  ghosttyConfig = pkgs.runCommand "ghostty-config" { } ''
    mkdir -p $out/themes
    cp ${../shared/config/ghostty/config} $out/config
    cp -R ${../shared/config/ghostty/themes}/. $out/themes/
    ln -s ${inputs.ghostty-shaders} $out/ghostty-shaders
  '';
in
{
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
    stateVersion = "25.11";
  };

  programs = import ../shared/home-manager.nix {
    inherit
      inputs
      config
      pkgs
      lib
      ;
  };

  manual.manpages.enable = lib.mkIf isDarwin false;

  xdg.configFile = {
    nvim = {
      source = inputs.sigmavim;
      recursive = true;
    };
    ghostty = {
      source = ghosttyConfig;
      recursive = true;
    };
    "starship.toml" = {
      source = ../shared/config/starship.toml;
    };
  };
}
