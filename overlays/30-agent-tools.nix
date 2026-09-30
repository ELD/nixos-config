{ llm-agents, ... }:
final: _:
let
  system = final.stdenv.hostPlatform.system;
in
{
  opencode = llm-agents.packages.${system}.opencode;
  codex = llm-agents.packages.${system}.codex;
  pi = llm-agents.packages.${system}.pi;
}
