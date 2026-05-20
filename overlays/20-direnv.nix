_: prev: {
  direnv = prev.direnv.overrideAttrs {
    doCheck = !prev.stdenv.hostPlatform.isDarwin;
  };
}
