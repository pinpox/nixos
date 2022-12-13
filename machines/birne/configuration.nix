# Configuration for birne
{ nixpkgs, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];


  /* services.navidrome = {
    enable = true;

    settings = {
    Address = "192.168.2.84";
    Port = 4533;
    MusicFolder = "/mnt/data/admin/ARCHIVE/Musik/Alphabetisch/";
    };
    };

    services.seafile = {

    enable = false;

    # Configuration for seafile-server, see https://manual.seafile.com/config/seafile-conf/
    seafileSettings = {
    fileserver = {
    port = 8082;
    host = "192.168.2.84";
    };

    };

    initialAdminPassword = "test";
    # Configuration for ccnet, see https://manual.seafile.com/config/ccnet-conf/
    ccnetSettings = { General = { SERVICE_URL = "https://seafile.pablo"; }; };

    adminEmail = "mail@pablo.tools";

    # Extra config to append to `seahub_settings.py` file. Refer to https://manual.seafile.com/config/seahub_settings_py/
    seahubExtraConf = "";

    };

    services.nginx = {
    enable = true;
    virtualHosts."seafile.pablo.tools" = {
    locations."/" = {
    proxyPass = "http://unix:/run/seahub/gunicorn.sock";
    # extraConfig = ''
    #   proxy_set_header X-Forwarded-Proto https;
    # '';
    };
    locations."/seafhttp" = {
    proxyPass = "http://127.0.0.1:8082";
    # extraConfig = ''
    #   rewrite ^/seafhttp(.*)$ $1 break;
    #   client_max_body_size 0;
    #   proxy_connect_timeout  36000s;
    #   proxy_set_header X-Forwarded-Proto https;
    #   proxy_set_header Host $host:$server_port;
    #   proxy_read_timeout  36000s;
    #   proxy_send_timeout  36000s;
    #   send_timeout  36000s;
    #   proxy_http_version 1.1;
    # '';
    };
    };
    };

    # "seafile.example.com" = {
    #   forceSSL = true;
    #   enableACME = true;
    #   locations."/" = {
    #     proxyPass =
    #       "http://unix:/var/run/seahub/gunicorn.sock";
    #   };

    # locations."/seafhttp" = {
    #   proxyPass =
    #     "http://127.0.0.1:${toString config.services.seafile.seafileSettings.fileserver.port}";
    # };
    # };
    # ```
  */

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  users.groups.nextcloud = { name = "nextcloud"; };

  users = {
    users.nextcloud = {
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ ./nextcloud-key-public ];
    };
  };

  # Host forwards incoming wg connections to the local network so we can reach LAN devices via wireguard. E.g. for retrieving stats directly from smart-home devices
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.wireguard.interfaces.wg0 =
    let
      iptables = "${nixpkgs.legacyPackages.x86_64-linux.iptables}/bin/iptables";
    in
    {
      postSetup = ''
        ${iptables} -t nat -A POSTROUTING -s 192.168.7.0/24 -o eno1 -j MASQUERADE; ${iptables} -A FORWARD -i wg0 -j ACCEPT
      '';

      postShutdown = ''
        ${iptables} -t nat -D POSTROUTING -s 192.168.7.0/24 -o eno1 -j MASQUERADE; ${iptables} -D FORWARD -i wg0 -j ACCEPT
      '';
    };

  services.garage = {
    enable = true;
    # extraEnvironment = { RUST_BACKTRACE = "yes"; }

    # https://garagehq.deuxfleurs.fr/reference_manual/configuration.html
    settings = {

      # https://garagehq.deuxfleurs.fr/reference_manual/configuration.html#replication_mode
      # replication_mode = "none";

      metadata_dir = "/var/lib/garage/meta";
      data_dir = "/var/lib/garage/data";

    };
  };

  pinpox = {

    server = {
      enable = true;
      hostname = "birne";
    };

    services = {

      minio.enable = true;

      # Backup up this host itself
      borg-backup.enable = true;

      # Set up borg repositories for all hosts
      borg-server.enable = true;

      borg-server.repositories = {
        kartoffel.authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHmA67Wm0zAJ+SK1/hhoTO4Zjwe2FyE/6DlyC4JD5S0X borg@kartoffel"
        ];

        porree.authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEi3WWUu3LXSckiOl1m+4Gjeb71ge7JV6IvBu9Y+R7uZ borg@porree"
        ];

        ahorn.authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMiQyd921cRNjN4+uGlHS0UjKV3iPTVOWBypvzJVJ6a borg@ahorn"
        ];

        birne.authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwlv5kttrOxSF9EWffxzj8SDEQvFnJbq139HEQsTLVV borg@birne"
        ];

        kfbox.authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6bgC5b0zWJTzI58zWGRdFtTvnS6EGeV9NKymVXf4Ht borg@kfbox"
        ];

        # mega.authorizedKeys = [
        #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW3f7nGeEDJIvu7LyLz/bWswPq9gR7AnC9vtiCmdG7C borg@mega"
        # ];

      };

      home-assistant.enable = true;
    };

    wg-client = {
      enable = true;
      clientIp = "192.168.7.4";
    };

    defaults = {
      lvm-grub.enable = true;
      environment.enable = true;
      locale.enable = true;
      nix.enable = true;
    };

    metrics.node.enable = true;
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "letsencrypt@pablo.tools";

  services.unifi.enable = true;
  services.unifi.unifiPackage = pkgs.unifi6;

  # Open ports in the firewall.
  networking.firewall = {

    allowedUDPPorts = [ 3478 ];
    allowedTCPPorts = [
      80
      443
      4533
      8080
      8443
    ];
  };
}
