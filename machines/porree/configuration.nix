{
  matrix-hook,
  config,
  pkgs,
  alertmanager-ntfy,
  pinpox-utils,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    matrix-hook.nixosModule
    alertmanager-ntfy.nixosModules.default
    ./caddy.nix
    # ./retiolum.nix
  ];

  clan.core.networking.targetHost = "94.16.108.229";
  networking.hostName = "porree";

  networking.interfaces.ens3 = {
    ipv6.addresses = [
      {
        address = "2a03:4000:51:aa3::1";
        prefixLength = 64;
      }
    ];
  };

  clan.core.vars.generators."matrix-hook" = pinpox-utils.mkEnvGenerator [ "MX_TOKEN" ];
  clan.core.vars.generators."alertmanager-ntfy" = pinpox-utils.mkEnvGenerator [
    "NTFY_USER"
    "NTFY_PASS"
  ];

  clan.core.vars.generators."authelia-user-pinpox" = {
    files.password = { };
    files.password-hash.owner = "authelia-main";
    runtimeInputs = with pkgs; [ coreutils authelia xkcdpass gnused ];
    script = ''
      mkdir -p $out
      xkcdpass -n 7 -d- > $out/password
      authelia crypto hash generate argon2 --password "$(cat $out/password)" | sed 's/^Digest: //' > $out/password-hash
    '';
  };

  clan.core.vars.generators."authelia-user-lislon" = {
    files.password = { };
    files.password-hash.owner = "authelia-main";
    runtimeInputs = with pkgs; [ coreutils authelia xkcdpass gnused ];
    script = ''
      mkdir -p $out
      xkcdpass -n 7 -d- > $out/password
      authelia crypto hash generate argon2 --password "$(cat $out/password)" | sed 's/^Digest: //' > $out/password-hash
    '';
  };

  clan.core.vars.generators."authelia-user-berber" = {
    files.password = { };
    files.password-hash.owner = "authelia-main";
    runtimeInputs = with pkgs; [ coreutils authelia xkcdpass gnused ];
    script = ''
      mkdir -p $out
      xkcdpass -n 7 -d- > $out/password
      authelia crypto hash generate argon2 --password "$(cat $out/password)" | sed 's/^Digest: //' > $out/password-hash
    '';
  };

  # OIDC client secret for miniflux (generated here, shared to kfbox)
  clan.core.vars.generators."miniflux-oidc" = {
    share = true;
    files.client_secret.owner = "authelia-main";
    runtimeInputs = with pkgs; [ coreutils openssl ];
    script = ''
      mkdir -p $out
      openssl rand -hex 32 > $out/client_secret
    '';
  };

  services.qemuGuest.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # Block anything that is not HTTP(s) or SSH.
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      80
      443
      22
    ];
    allowedUDPPorts = [ 51820 ];

    interfaces.wg-clan.allowedTCPPorts = [
      2812
      8086 # InfluxDB
    ];
  };

  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/sda";
  boot.loader.timeout = 0;

  programs.ssh.startAgent = false;

  services.alertmanager-ntfy = {
    enable = true;
    httpAddress = "localhost";
    httpPort = "9099";
    ntfyTopic = "https://push.pablo.tools/pinpox_alertmanager";
    ntfyPriority = "default";
    envFile = "${config.clan.core.vars.generators."alertmanager-ntfy".files."envfile".path}";
  };

  pinpox = {

    services = {
      opencrow.enable = true;
      authelia = {
        enable = true;
        declarativeUsers = {
          enable = true;
          users = {
            pinpox = {
              displayname = "pinpox";
              email = "mail@pablo.tools";
              groups = [ "admins" "users" "miniflux-users" "opencloud-users" ];
              passwordFile = config.clan.core.vars.generators."authelia-user-pinpox".files.password-hash.path;
            };
            lislon = {
              displayname = "lislon";
              email = "lislon@pablo.tools";
              groups = [ "users" ];
              passwordFile = config.clan.core.vars.generators."authelia-user-lislon".files.password-hash.path;
            };
            berber = {
              displayname = "berber";
              email = "berber@pablo.tools";
              groups = [ "users" "opencloud-users" "miniflux-users" ];
              passwordFile = config.clan.core.vars.generators."authelia-user-berber".files.password-hash.path;
            };
          };
        };
        oidcAuthorizationPolicies = {
          opencloud-policy = {
            default_policy = "deny";
            rules = [
              { policy = "one_factor"; subject = "group:opencloud-users"; }
            ];
          };
          miniflux-policy = {
            default_policy = "deny";
            rules = [
              { policy = "one_factor"; subject = "group:miniflux-users"; }
            ];
          };
        };
        oidcClients = [
          {
            client_id = "miniflux";
            # Secret is shared via clan vars (share = true)
            client_secret_file = config.clan.core.vars.generators."miniflux-oidc".files.client_secret.path;
            redirect_uris = [ "https://news.0cx.de/oauth2/oidc/callback" ];
            scopes = [ "openid" "profile" "email" ];
            authorization_policy = "miniflux-policy";
            token_endpoint_auth_method = "client_secret_basic";
          }
          {
            # OpenCloud uses public client with PKCE (no secret needed)
            client_id = "opencloud";
            client_name = "OpenCloud";
            public = true;
            authorization_policy = "opencloud-policy";
            require_pkce = true;
            pkce_challenge_method = "S256";
            scopes = [ "openid" "offline_access" "groups" "profile" "email" ];
            redirect_uris = [
              "https://cloud.pablo.tools/"
              "https://cloud.pablo.tools/oidc-callback.html"
              "https://cloud.pablo.tools/oidc-silent-redirect.html"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" "refresh_token" ];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "none";
          }
        ];
      };
      vaultwarden.enable = true;
      ntfy-sh.enable = true;

      matrix-hook = {
        enable = true;
        httpAddress = "localhost";
        matrixHomeserver = "https://matrix.org";
        matrixUser = "@alertus-maximus:matrix.org";
        matrixRoom = "!ilXTQgAfoBlNBuDmsz:matrix.org";
        envFile = "${config.clan.core.vars.generators."matrix-hook".files."envfile".path}";
        msgTemplatePath = "${matrix-hook.packages."x86_64-linux".matrix-hook}/bin/message.html.tmpl";
      };

      # Enable nextcloud configuration
      nextcloud.enable = true;

      # Enable OpenCloud (uses Authelia OIDC)
      opencloud.enable = true;

      monitoring-server = {

        enable = true;
        dashboard.enable = true;
        loki.enable = true;
        alertmanager-irc-relay.enable = true;

        blackboxTargets = [
          "https://pablo.tools"
          "https://megaclan3000.de"
          "https://build.lounge.rocks"
          # "https://lounge.rocks"
          # "https://vpn.pablo.tools"
          "https://${config.pinpox.services.vaultwarden.host}" # Vaultwarden
          "https://pinpox.github.io/nixos/"
          "https://cache.lounge.rocks/nix-cache/nix-cache-info"
          # "https://pads.0cx.de"
          "https://news.0cx.de"
          # Gitea (on kfbox with host set to default vaulue)
          "https://${config.pinpox.services.gitea.host}"
          "https://irc.0cx.de"
        ];
      };
    };

    metrics = {
      blackbox.enable = true;
      json.enable = true;
    };
  };
}
