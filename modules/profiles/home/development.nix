{ pkgs, ... }:
{
  imports = [ ./stack.nix ];
  home.packages = [ pkgs.just ];
}
