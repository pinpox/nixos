{
  distro,
  mics-skills,
  pkgs,
  ...
}:
{
  imports = [
    distro.nixosModules.noctalia-plugin
  ];

  services.opencrow-local = {
    enable = true;
    instanceName = "geninf";
    piPackage = pkgs.pi;
    llmUrl = "http://127.0.0.1:8012";
    model = "gemma4:e2b";
    socketName = "GenInf Crow";
    noctaliaPlugin = true;
    skills = {
      deutschebahn = "${mics-skills.packages.${pkgs.system}.db-cli}/share/skills/db-cli";
    };
    extraPackages = [
      pkgs.pi
      pkgs.curl
      pkgs.jq
      mics-skills.packages.${pkgs.system}.db-cli
    ];
  };
}
