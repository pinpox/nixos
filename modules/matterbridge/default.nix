
{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.matterbridge;

init-script = pkgs.writeScriptBin "write-config" ''
      #!${pkgs.stdenv.shell}
      mkdir -p /var/lib/matterbridge
      cat /var/src/secrets/matterbridge/config.toml > /var/lib/matterbridge/config.toml
      chown -R matterbridge:matterbridge /var/lib/matterbridge
      chmod -R 644 /var/lib/matterbridge
    '';
in {

  options.pinpox.services.matterbridge = {
    enable = mkEnableOption "matterbridge setup";
  };

  config = mkIf cfg.enable {

    services.matterbridge = {
      enable = true;
      configPath = "/var/lib/matterbridge/config.toml";
    };


    systemd.services.matterbridge= {
      serviceConfig = {
        preStart = "+${init-script}/bin/write-config";
      };
    };
  };
}
