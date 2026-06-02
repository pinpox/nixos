{
  config,
  spaces,
  mics-skills,
  pkgs,
  ...
}:
{
  imports = [
    spaces.nixosModules.pi-chat
  ];

  clan.core.vars.generators."pi-chat-openrouter".prompts."api-key".persist = true;

  services.pi-chat = {
    enable = true;
    piPackage = pkgs.pi;
    llmUrl = "http://127.0.0.1:8012";
    openrouter = {
      enable = true;
      apiKeyFile = config.clan.core.vars.generators."pi-chat-openrouter".files."api-key".path;
    };
    skills = {
      deutschebahn = "${
        mics-skills.packages.${pkgs.stdenv.hostPlatform.system}.db-cli
      }/share/skills/db-cli";
    };
  };

  # opencrow-local's extraPackages installed binaries inside its scope.
  # pi-chat's sandbox inherits the user's PATH, so adding them as system
  # packages makes them reachable to the agent (and to you in a normal
  # terminal). Verified by the upstream `pi-chat-skill-clis-on-path` check.
  environment.systemPackages = [
    pkgs.pi
    pkgs.curl
    pkgs.jq
    mics-skills.packages.${pkgs.stdenv.hostPlatform.system}.db-cli
  ];
}
