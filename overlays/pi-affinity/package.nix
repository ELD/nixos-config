{ lib, pi }:

let
  # buildEnv merges libexec as well as bin. Namespace every upstream reference,
  # including the wrapper, Darwin signing hook and native-module install check.
  affinityLayout = lib.replaceStrings [ "$out/libexec/pi" ] [ "$out/libexec/pi-affinity" ];
in
pi.overrideAttrs (old: {
  pname = "pi-affinity";

  # llm-agents builds the published JS, not the upstream TypeScript checkout.
  # Dependencies only exist after npmConfigHook, so normal `patches` is too early.
  postConfigure = (old.postConfigure or "") + ''
    patch --batch --fuzz=0 -d node_modules/@earendil-works/pi-ai -p1 \
      < ${./codex-routing.patch}
    node ${./test-routing.cjs} node_modules/@earendil-works/pi-ai/dist/api/openai-codex-responses.js
  '';

  postFixup = affinityLayout (old.postFixup or "");
  postInstallCheck = affinityLayout (old.postInstallCheck or "");

  postInstall = affinityLayout (old.postInstall or "") + ''
    # The upstream standalone layout discards the SDK. Keep a matching patched
    # npm tree so native pi-subagents children cannot fall back to stock pi-ai.
    sdkdir="$out/libexec/pi-affinity-sdk"
    mkdir -p "$sdkdir"
    cp -R package.json dist node_modules docs examples "$sdkdir/"
    rm -f "$sdkdir/dist/pi"
    find "$sdkdir" -type f -name '*.js' -exec chmod -x {} +

    # Preserve upstream's PATH/assets/telemetry wrapper, but expose only `pia`.
    mv "$out/bin/pi" "$out/bin/pia"
    wrapProgram "$out/bin/pia" \
      --set PI_CODEX_AFFINITY_CORE 1 \
      --set PI_SUBAGENTS_PI_CODING_AGENT_PACKAGE_ROOT "$sdkdir" \
      --set PI_SUBAGENT_PI_BINARY "$out/bin/pia"
  '';

  meta = (old.meta or { }) // {
    description = "Pi with opt-in Codex child-session routing affinity (pia)";
    mainProgram = "pia";
  };
})
