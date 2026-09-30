{ zig, ... }:
_: prev: {
  zigpkgs = zig.packages.${prev.stdenv.hostPlatform.system};
}
