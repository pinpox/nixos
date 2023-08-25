# Configuration for birne
{ nixpkgs, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

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

  # Access locally via:
  # https://birne:8443/manage/
  services.unifi = {
    enable = true;

    # 6 is latest supported for my access points. Beware that this will build
    # an older version of mongodb (from source), which may cause slow rebuilds
    # if it's not cached.
    unifiPackage = pkgs.unifi6;

    # Open required ports
    openFirewall = true;
    # tcp/8080  # Port for UAP to inform controller.
    # tcp/8880  # Port for HTTP portal redirect, if guest portal is enabled.
    # tcp/8843  # Port for HTTPS portal redirect, ditto.
    # tcp/6789  # Port for UniFi mobile speed test.
    # udp/3478  # UDP port used for STUN.
    # udp/10001 # UDP port used for device discovery.
  };

  # Open ports in the firewall.
  networking.firewall = {

    allowedUDPPorts = [ 3478 ];
    allowedTCPPorts = [
      80
      443
      # 8443
      4533
    ];
  };
}
