args:
let
  path = ./.;
  loadOverlay =
    name:
    let
      entry = path + ("/" + name);
      target = if builtins.pathExists (entry + "/default.nix") then entry + "/default.nix" else entry;
      overlay = import target;
    in
    if builtins.isFunction overlay && builtins.functionArgs overlay != { } then
      overlay (builtins.intersectAttrs (builtins.functionArgs overlay) args)
    else
      overlay;
in
with builtins;
map loadOverlay (
  filter (
    name:
    name != "default.nix"
    && (match ".*\\.nix" name != null || pathExists (path + ("/" + name + "/default.nix")))
  ) (attrNames (readDir path))
)
