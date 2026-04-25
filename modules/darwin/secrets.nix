{ secrets, ... }:

let
  user = "edattore";
  hostSecrets = "${secrets}/hosts/rhodium.yaml";
in
{
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFormat = "yaml";

    secrets = {
      "mac-licenses" = {
        sopsFile = hostSecrets;
        key = "mac_licenses";
        path = "/Users/${user}/mac-licenses.md";
        mode = "0600";
        owner = user;
        group = "staff";
      };

      "netrc" = {
        sopsFile = hostSecrets;
        key = "netrc";
        path = "/Users/${user}/.netrc";
        mode = "0600";
        owner = user;
        group = "staff";
      };

      "openai-env" = {
        sopsFile = hostSecrets;
        key = "openai_env";
        path = "/Users/${user}/.access/openai-env.sh";
        mode = "0600";
        owner = user;
        group = "staff";
      };
    };
  };
}
