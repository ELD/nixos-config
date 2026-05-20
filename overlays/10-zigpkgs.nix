{ zig, ... }:
final: prev: {
  zigpkgs = zig.packages.${prev.stdenv.hostPlatform.system};
}
