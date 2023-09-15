{ lib, config, ... }:
with lib;
let cfg = config.pinpox.services.kf-homepage;
in
{

  options.pinpox.services.kf-homepage = {
    enable = mkEnableOption "Krosse Flagge Homepage";
  };

  config = mkIf cfg.enable {

    services.caddy = {
      enable = true;
      virtualHosts = {
        "0cx.de".extraConfig = ''
          root * ${./page}
          encode zstd gzip
          file_server
        '';


        # ## It is important to read the following document before enabling this section:
        # ##     https://www.authelia.com/integration/proxies/caddy/#forwarded-header-trust#trusted-proxies
        # (trusted_proxy_list) {
        #        ## Uncomment & adjust the following line to configure specific ranges which should be considered as trustworthy.
        #        # trusted_proxies 10.0.0.0/8 172.16.0.0/16 192.168.0.0/16 fc00::/7
        # }

        # # Authelia Portal.
        # auth.example.com {
        #         reverse_proxy authelia:9091 {
        #                 ## This import needs to be included if you're relying on a trusted proxies configuration.
        #                 import trusted_proxy_list
        #         }
        # }

        # # Protected Endpoint.
        # nextcloud.example.com {
        #         forward_auth authelia:9091 {
        #                 uri /api/verify?rd=https://auth.example.com/
        #                 copy_headers Remote-User Remote-Groups Remote-Name Remote-Email

        #                 ## This import needs to be included if you're relying on a trusted proxies configuration.
        #                 import trusted_proxy_list
        #         }
        #         reverse_proxy nextcloud:80 {
        #                 ## This import needs to be included if you're relying on a trusted proxies configuration.
        #                 import trusted_proxy_list
        #         }
        # }
      };
    };
  };
}
