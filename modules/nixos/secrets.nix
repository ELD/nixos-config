{ secrets, ... }:

let
  user = "edattore";
in
{
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFormat = "yaml";

    # Add per-host or shared secrets here as they become needed on Linux hosts.
    #
    # sops.secrets."github-ssh-key" = {
    #   sopsFile = "${secrets}/hosts/indium.yaml";
    #   key = "github_ssh_key";
    #   path = "/home/${user}/.ssh/id_github";
    #   mode = "0600";
    #   owner = user;
    # };
  };

}
