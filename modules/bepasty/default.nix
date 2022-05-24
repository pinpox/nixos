# TODO bepasty service is currently broken due to:
# https://github.com/NixOS/nixpkgs/issues/116326
# https://github.com/bepasty/bepasty-server/issues/258
# ./modules/bepasty/default.nix
{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.bepasty;
  bepasty-host = "paste.lounge.rocks";
in
{

  options.pinpox.services.bepasty = {
    enable = mkEnableOption "bepasty server";
  };

  config = mkIf cfg.enable {
    services.bepasty = {
      enable = true;
      servers."${bepasty-host}" = {
        secretKeyFile = "/var/src/secrets/bepasty/key";
        # extraConfig = '' '' ;
        bind = "0.0.0.0:8000";
      };
    };
  };

  # security.acme.acceptTerms = true;
  # security.acme.defaults.email = "letsencrypt@pablo.tools";

  # services.nginx = {
  #   enable = true;
  #   recommendedOptimisation = true;
  #   recommendedTlsSettings = true;
  #   clientMaxBodySize = "128m";
  #   recommendedProxySettings = true;
  #   commonHttpConfig = ''
  #     server_names_hash_bucket_size 128;
  #   '';
  #   virtualHosts = {
  #     "${bepasty-host}" = {
  #       forceSSL = true;
  #       enableACME = true;
  #       locations."/" = { proxyPass = "http://127.0.0.1:8000"; };
  #     };
  #   };
  # };
}
