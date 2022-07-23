{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.binary-cache;
in
{

  options.pinpox.services.binary-cache = {
    enable = mkEnableOption "binary-cache setup";
  };

  config = mkIf cfg.enable {

    # TODO remove when https://github.com/edolstra/nix-serve/issues/28 is fixed
    # This is a workaround, since nix-serve has problems with newer nix versions
    # nixpkgs.overlays = [
    #   (self: super: {
    #     nix-serve = super.nix-serve.override { nix = pkgs.nix_2_3; };
    #   })
    # ];

    lollypops.secrets.files = {
      "binary-cache/cache-priv-key.pem" = { };
      "binary-cache/cache-priv-key.pem" = { };
    };

    users = {
      users = {

        # User for nix-serve
        nix-serve = {
          group = "nix-serve";
          isSystemUser = true;
        };

        # User to push to the cache
        push-cache = {
          isNormalUser = true;
          description = "System user to push to the store";
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBrA5uESLJgMkrFU8MLDSjA2x792iizCet6/H7Z0j8Xn nix-serve@ssh"
          ];
        };
      };

      groups.nix-serve = { };
    };

    nix.settings.allowed-users = [ "nix-serve" "push-cache" ];

    nix.extraOptions = ''
      secret-key-files = ${config.lollypops.secrets.files."binary-cache/cache-priv-key.pem".path}
    '';

    services.nix-serve = {
      enable = true;
      secretKeyFile = config.lollypops.secrets.files."binary-cache/cache-priv-key.pem".path;
    };
    /* nix.extraOptions = let
      upload-script = pkgs.writeShellScript "upload-to-cache" ''

      #!/bin/sh

      set -eu
      set -f # disable globbing
      export IFS=' '

      echo "Signing paths" $OUT_PATHS
      nix store sign --key-file /run/keys/cache-priv-key $OUT_PATHS
      echo "Uploading paths" $OUT_PATHS
      exec nix copy --to 's3://example-nix-cache?scheme=https&region=eu-central-1&endpoint=s3.lounge.rocks' $OUT_PATHS
      '';
      in ''
      post-build-hook = ${upload-script}
      '';
    */

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
