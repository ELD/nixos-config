# Tools currently used on the personal Mac and Indium, not assumed on a new work host.
{ pkgs, ... }:
{
  programs.bacon.enable = true;
  programs.git.signing = {
    key = "0x26CCB5CE8AE20CE0";
    signByDefault = true;
  };
  home.packages = with pkgs; [
    iamb
    attic-client
    yubikey-manager
    jdk
    fontforge
    lazysql
    yt-dlp
    luajit
    luajitPackages.luarocks
    doctl
    flyctl
    terraform
    turso-cli
    bacon
    cargo-nextest
    cargo-expand
    cargo-outdated
    cargo-shuttle
    cargo-sweep
    cargo-vet
    cargo-wipe
    diesel-cli
    evcxr
    rustup
    sqlx-cli
    sccache
    tectonic
    typst
    texliveFull
    codex
    opencode
    pi
    tuicr
    zigpkgs.master
    wrangler
    cloudflared
  ];
}
