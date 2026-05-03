{ zig, ... }:
final: prev: {
  zigpkgs = zig.packages.${final.stdenv.hostPlatform.system};
}
