{ pkgs, config, ... }:

let bepasty-host = "paste.lounge.rocks";
in {
  services.bepasty = {
    enable = true;
    servers."${bepasty-host}" = {
      secretKeyFile = "/var/src/secrets/bepasty/key";
      # extraConfig = '' '' ;
      bind = "0.0.0.0:8000";
    };
  };

  # security.acme.acceptTerms = true;
  # security.acme.email = "letsencrypt@pablo.tools";

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
