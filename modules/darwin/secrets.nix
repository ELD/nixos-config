{ config, lib, pkgs, agenix, secrets, ... }:

let user = "edattore"; in
{
  age = {
    identityPaths = [
      "${secrets}/identities/edattore-5c.txt"
    ];
    ageBin = "PATH=$PATH:${lib.makeBinPath [pkgs.age-plugin-yubikey]} ${pkgs.age}/bin/age";
    # Your secrets go here
    #
    # Note: the installWithSecrets command you ran to boostrap the machine actually copies over
    #       a Github key pair. However, if you want to store the keypair in your nix-secrets repo
    #       instead, you can reference the age files and specify the symlink path here. Then add your
    #       public key in shared/files.nix.
    #
    #       If you change the key name, you'll need to update the SSH configuration in shared/home-manager.nix
    #       so Github reads it correctly.


    secrets = {
      "mac-licenses" = {
        symlink = true;
        path = "/Users/${user}/mac-licenses.md";
        file =  "${secrets}/mac-licenses.age";
        mode = "600";
        owner = "${user}";
        group = "staff";
      };

      "netrc" = {
        symlink = false;
        path = "/Users/${user}/.netrc";
        file =  "${secrets}/netrc.age";
        mode = "600";
        owner = "${user}";
      };

      "openai-env" = {
        symlink = true;
        path = "/Users/${user}/.access/openai-env.sh";
        file = "${secrets}/openai-env.age";
        mode = "600";
        owner = "${user}";
        group = "staff";
      };
    };
  };
}
