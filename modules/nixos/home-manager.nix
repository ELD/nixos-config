{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  user = "edattore";
  shared-programs = import ../shared/home-manager.nix {
    inherit
      inputs
      config
      pkgs
      lib
      ;
  };
  shared-files = import ../shared/files.nix { inherit config pkgs; };

in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix { };
    file = shared-files // import ./files.nix { inherit pkgs user; };
    stateVersion = "25.11";
  };

  # Use a dark theme
  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    gtk4.theme = config.gtk.theme;
  };

  services = {
    # Auto mount devices
    udiskie.enable = true;
  };

  programs = shared-programs // {
    gpg.enable = true;
  };

}
