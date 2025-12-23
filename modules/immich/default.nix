{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.immich;
in
{

  options.pinpox.services.immich = {
    enable = mkEnableOption "immich photo gallery";

    host = mkOption {
      type = types.str;
      default = "photos.0cx.de";
      description = "Host serving immich";
      example = "pics.0cx.de";
    };

  };

  config = mkIf cfg.enable {

    # services.immich-public-proxy.enable
    # services.immich-public-proxy.immichUrl
    # services.immich-public-proxy.openFirewall
    # services.immich-public-proxy.package
    # services.immich-public-proxy.port
    # services.immich-public-proxy.settings

    services.immich = {

      enable = true;
      host = "127.0.0.1";

      # environment
      # openFirewall
      # secretsFile
      mediaLocation = "/mnt/storagebox/photos";

      # settings
      # Configuration for Immich. See https://immich.app/docs/install/config-file/ or
      # navigate to https://my.immich.app/admin/system-settings for options and
      # defaults. Setting it to null allows configuring Immich in the web interface.
      # You can load secret values from a file in this configuration by setting
      # somevalue._secret = "/path/to/file" instead of setting somevalue directly.

      settings = {

        server.externalDomain = "https://${cfg.host}";
        storageTemplate = {
          enabled = true;
          hashVerificationEnabled = true;
          template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
        };

      };
      #   storageTemplate = {
      #     enabled = true;
      #     hashVerificationEnabled = true;
      #     # template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
      #   };
      #   #   passwordLogin.enabled = false;
      #   #   oauth = { };
      # };

      # "oauth": {
      #    "autoLaunch": false,
      #    "autoRegister": true,
      #    "buttonText": "Login with OAuth",
      #    "clientId": "",
      #    "clientSecret": "",
      #    "defaultStorageQuota": null,
      #    "enabled": false,
      #    "issuerUrl": "",
      #    "mobileOverrideEnabled": false,
      #    "mobileRedirectUri": "",
      #    "profileSigningAlgorithm": "none",
      #    "roleClaim": "immich_role",
      #    "scope": "openid email profile",
      #    "signingAlgorithm": "RS256",
      #    "storageLabelClaim": "preferred_username",
      #    "storageQuotaClaim": "immich_quota",
      #    "timeout": 30000,
      #    "tokenEndpointAuthMethod": "client_secret_post"
      #  },
      #  },

    };

    # Reverse proxy
    services.caddy = {
      enable = true;
      virtualHosts."${cfg.host}".extraConfig =
        "reverse_proxy 127.0.0.1:${toString config.services.immich.port}";
    };

    # Mount storagebox
    pinpox.defaults.storagebox = {
      enable = true;
      mountOnAccess = false;
    };

    # Add immich user to storage-users group for access to storagebox
    users.users.${config.services.immich.user}.extraGroups = [ "storage-users" ];

    # Ensure storagebox is mounted before immich starts
    systemd.services.immich-server = {
      requires = [ "mnt-storagebox.mount" ];
      after = [ "mnt-storagebox.mount" ];
    };
  };
}
