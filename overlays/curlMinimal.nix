self: super: {
  # curlMinimal = super.curlMinimal.overrideAttrs (old: {
  #   patches = (old.patches or []) ++ [
  #     ./curlMinimal-patches/fix-netrc-regression.patch
  #     ./curlMinimal-patches/fix-netrc-regression-2.patch
  #   ];
  # });
}
