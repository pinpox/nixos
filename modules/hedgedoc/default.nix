{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.services.hedgedoc;
in
{

  options.pinpox.services.hedgedoc = {
    enable = mkEnableOption "Hedgedoc server";
  };
  config = mkIf cfg.enable {

    lollypops.secrets.files."hedgedoc/envfile" = { };

    # Create system user and group
    services.hedgedoc = {
      enable = true;
      environmentFile = "${config.lollypops.secrets.files."hedgedoc/envfile".path}";
      configuration = {

        protocolUseSSL = true; # Use https when loading assets
        allowEmailRegister = false; # Disable email registration
        email = false; # Disable email login

        domain = "pads.0cx.de";
        # host = "127.0.0.1"; # Default
        # port = 3000; # Default
        # allowOrigin = [ "localhost" ]; # TODO not sure if neeeded
        debug = true;

        db = {
          dialect = "sqlite";
          storage = "/var/lib/hedgedoc/db.sqlite";
        };

        useCDN = true;
      };
    };
  };
}
