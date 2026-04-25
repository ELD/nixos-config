{ llm-agents, ... }:
final: prev:
let
  system = final.stdenv.hostPlatform.system;
in
{
  opencode = llm-agents.packages.${system}.opencode;
}
