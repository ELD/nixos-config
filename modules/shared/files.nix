{
  pkgs,
  config,
  profile ? "full",
  ...
}:

if profile == "vm" then
  { }
else
  {
    ".cargo/config.toml".source = (pkgs.formats.toml { }).generate "cargo-config" {
      build = {
        rustc-wrapper = "${pkgs.sccache}/bin/sccache";
      };
      alias = {
        b = "build";
        t = "test";
        c = "clippy";
        r = "run";
        rr = "run --release";
        br = "build --release";
      };
    };
  }
