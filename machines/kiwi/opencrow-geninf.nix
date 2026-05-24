{
  config,
  distro,
  mics-skills,
  pinpox-utils,
  pkgs,
  ...
}:
{
  imports = [
    distro.nixosModules.noctalia-plugin
  ];

  clan.core.vars.generators."opencrow-17track" = pinpox-utils.mkEnvGenerator [
    "TRACK17_API_KEY"
  ];

  services.opencrow-local = {
    enable = true;
    instanceName = "geninf";
    piPackage = pkgs.pi;
    llmUrl = "http://127.0.0.1:8012";
    socketName = "GenInf Crow";
    noctaliaPlugin = true;
    skills = {
      deutschebahn = "${mics-skills.packages.${pkgs.system}.db-cli}/share/skills/db-cli";
      deliveries = ../../skills/deliveries;
    };
    environmentFiles = [
      config.clan.core.vars.generators."opencrow-17track".files."envfile".path
    ];
    extraPackages = [
      pkgs.pi
      pkgs.curl
      pkgs.jq
      mics-skills.packages.${pkgs.system}.db-cli
      (pkgs.callPackage ../../packages/delivery-cli { })
    ];
  };
}
