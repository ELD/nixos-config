{ zig, ... }:
final: prev: {
  zigpkgs = zig.packages.${prev.system};
}
