{ host, ... }:

if host ? secretsFile && host.secrets.repo == "personal" then
  {
    sops = {
      age.keyFile = "/var/lib/sops-nix/key.txt";
      defaultSopsFormat = "yaml";

      secrets = {
        "mac-licenses" = {
          sopsFile = host.secretsFile;
          key = "mac_licenses";
          path = "${host.homeDirectory}/mac-licenses.md";
          mode = "0600";
          owner = host.username;
          group = "staff";
        };

        "netrc" = {
          sopsFile = host.secretsFile;
          key = "netrc";
          path = "${host.homeDirectory}/.netrc";
          mode = "0600";
          owner = host.username;
          group = "staff";
        };

        "openai-env" = {
          sopsFile = host.secretsFile;
          key = "openai_env";
          path = "${host.homeDirectory}/.access/openai-env.sh";
          mode = "0600";
          owner = host.username;
          group = "staff";
        };
      };
    };
  }
else
  { }
