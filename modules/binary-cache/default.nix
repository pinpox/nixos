{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.binary-cache;
  init-script = pkgs.writeScriptBin "write-key" ''
    #!${pkgs.stdenv.shell}
    cat /var/src/secrets/binary-cache/cache-priv-key.pem > /var/lib/cache-priv-key.pem
    chown nix-serve /var/cache-priv-key.pem
    chmod 600 /var/cache-priv-key.pem
  '';
in {

  options.pinpox.services.binary-cache = {
    enable = mkEnableOption "binary-cache setup";
  };

  config = mkIf cfg.enable {
    services.nix-serve = {
      enable = true;
      secretKeyFile = "/var/cache-priv-key.pem";
    };

    systemd.services.nix-serve = {
      serviceConfig = { preStart = "+${init-script}/bin/write-key"; };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "cache.lounge.rocks" = {
          serverAliases = [ "binarycache" ];
          locations."/".extraConfig = ''
            proxy_pass http://localhost:${
              toString config.services.nix-serve.port
            };
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
    };
  };
}
