{ pkgs, ... }:
{

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowInsecure = false;
      permittedInsecurePackages = [ "olm-3.2.16" ];
    };
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
