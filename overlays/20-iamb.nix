final: prev: {
  iamb = prev.iamb.overrideAttrs {
    patches = [
      ./iamb/0001-increase-recursion-limit-to-fix-matrix-sdk-sqlite.patch
    ];
  };
}
