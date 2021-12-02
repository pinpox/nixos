{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.binary-cache;
  init-script = pkgs.writeScriptBin "write-key" ''
    #!${pkgs.stdenv.shell}
    cat /var/src/secrets/binary-cache/cache-priv-key.pem > /var/lib/cache-priv-key.pem
    chown nix-serve /var/lib/cache-priv-key.pem
    chmod 600 /var/lib/cache-priv-key.pem
  '';
in {

  options.pinpox.services.binary-cache = {
    enable = mkEnableOption "binary-cache setup";
  };

  config = mkIf cfg.enable {

    # TODO remove when https://github.com/edolstra/nix-serve/issues/28 is fixed
    # This is a workaround, since nix-serve has problems with newer nix versions
    nixpkgs.overlays = [
      (self: super: {
        nix-serve = super.nix-serve.override { nix = pkgs.nix_2_3; };
      })
    ];

    services.nix-serve = {
      enable = true;
      secretKeyFile = "/var/lib/cache-priv-key.pem";
    };

    # TODO fix this, currently broken, ispreStart is not a valid key
    users.users.push-cache = {
      isNormalUser = true;
      description = "System user to push to the store";
      extraGroups = [ ];

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBrA5uESLJgMkrFU8MLDSjA2x792iizCet6/H7Z0j8Xn nix-serve@ssh"
      ];
    };

    systemd.services.nix-serve = {
      serviceConfig = { preStart = "+${init-script}/bin/write-key"; };
    };

    nix.allowedUsers = [ "nix-serve" "push-cache" ];

    services.nginx = {
      enable = true;
      virtualHosts = {

        "cache.lounge.rocks" = {
          addSSL = true;
          enableACME = true;
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
