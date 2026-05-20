{ host, sops-nix, ... }:
{
  imports = [
    ../../modules/darwin/base-home-manager.nix
    sops-nix.darwinModules.sops
  ];

  nix.enable = false; # Nix is installed separately (Determinate).
  networking = {
    computerName = host.hostname;
    hostName = host.hostname;
    localHostName = host.hostname;
  };
  system.primaryUser = host.username;
  system.stateVersion = host.stateVersion;
}
