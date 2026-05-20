# Python, TypeScript/JavaScript, and Go tooling common to development and work.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.jupyter-core
    python3Packages.ipython
    python3Packages.ipykernel
    python3Packages.fonttools
    pylint
    pipenv
    bun
    nodejs_latest
    pnpm
    yarn
    go
    air
    golangci-lint
    templ
  ];
}
