{
  distro,
  mics-skills,
  pkgs,
  ...
}:
{
  imports = [
    distro.nixosModules.pi-chat
  ];

  services.pi-chat = {
    enable = true;
    piPackage = pkgs.pi;
    llmUrl = "http://127.0.0.1:8012";
    skills = {
      deutschebahn = "${mics-skills.packages.${pkgs.system}.db-cli}/share/skills/db-cli";
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
    mics-skills.packages.${pkgs.system}.db-cli
  ];
}
