{ config, pkgs, ... }:
{

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    overlays =
      # Apply each overlay found in the /overlays directory
      let path = ../../overlays; in with builtins;
      map (n: import (path + ("/" + n)))
          (filter (n: match ".*\\.nix" n != null ||
                      pathExists (path + ("/" + n + "/default.nix")))
                  (attrNames (readDir path)));
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  fonts = {
    packages = with pkgs; [
      open-sans
      nerd-fonts.jetbrains-mono
      nerd-fonts.recursive-mono
      nerd-fonts.monaspace
      # (nerdfonts.override {
      #   fonts = [
      #     "JetBrainsMono"
      #     "Recursive"
      #     "Monaspace"
      #   ];
      # })
    ];
  };
}
