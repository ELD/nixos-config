{
  host,
  homeProfileModules,
  pkgs,
  ...
}:

{
  users.users.${host.username} = {
    name = host.username;
    home = host.homeDirectory;
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager = {
    extraSpecialArgs.host = host;
    useGlobalPkgs = true;
    users.${host.username} = {
      imports = [ ../home-manager ] ++ homeProfileModules;
      home = {
        inherit (host) username homeDirectory;
      };
    };
  };
}
