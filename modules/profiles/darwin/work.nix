{ host, ... }:
{
  # No employer-specific secret names or paths until onboarding. Opting into
  # work secrets only selects the SOPS source and key location for future rules.
  sops =
    if host ? secretsFile && host.secrets.repo == "work" then
      {
        defaultSopsFile = host.secretsFile;
        defaultSopsFormat = "yaml";
        age.keyFile = "/var/lib/sops-nix/work-key.txt";
      }
    else
      { };
}
