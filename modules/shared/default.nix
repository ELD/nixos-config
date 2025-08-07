{ config, pkgs, ... }:
{

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
      permittedInsecurePackages = [ "olm-3.2.16" ];
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
    backupFileExtension = "old.bak";
  };

  fonts = {
    packages = with pkgs; [
      open-sans
      nerd-fonts.jetbrains-mono
      nerd-fonts.recursive-mono
      nerd-fonts.monaspace
    ];
  };
}
