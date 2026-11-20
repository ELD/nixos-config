{ llm-agents, ... }:
final: _:
let
  system = final.stdenv.hostPlatform.system;
in
{
  opencode = llm-agents.packages.${system}.opencode;
  opencode2 = llm-agents.packages.${system}.opencode2;
  codex = llm-agents.packages.${system}.codex;
  pi = llm-agents.packages.${system}.pi;
  pi-affinity = final.callPackage ./pi-affinity/package.nix {
    pi = llm-agents.packages.${system}.pi;
  };
}
