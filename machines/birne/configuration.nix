# Configuration for birne

{ config, pkgs, ... }: {

  networking.hostName = "birne"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # Users allowed to run nix
    allowedUsers = [ "root" ];
  };

  # Enable Wireguard
  networking.wireguard.interfaces = {

    wg0 = {

      # Determines the IP address and subnet of the client's end of the
      # tunnel interface.
      ips = [ "192.168.7.4/24" ];

      # Path to the private key file
      privateKeyFile = toString /var/src/secrets/wireguard/private;
      peers = [{
        # Public key of the server (not a file path).
        publicKey = "XKqEk5Hsp3SRVPrhWD2eLFTVEYb9NYRky6AermPG8hU=";

        # Don't forward all the traffic via VPN, only particular subnets
        allowedIPs = [ "192.168.7.0/24" ];

        # Server IP and port.
        endpoint = "vpn.pablo.tools:51820";

        # Send keepalives every 25 seconds. Important to keep NAT tables
        # alive.
        persistentKeepalive = 25;
      }];
    };
  };

  security.acme.acceptTerms = true;
  security.acme.email = "letsencrypt@pablo.tools";

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "128m";

    virtualHosts = {
      # Password manager (bitwarden) instance
      "cloud.pablo.tools" = {
        forceSSL = true;
        enableACME = true;

        # TODO remove this when seafile is setup
        root = "/var/www/statuspage";
        # locations."/" = { proxyPass = "http://127.0.0.1:8080"; };
      };
    };
  };

  nixpkgs = { config.allowUnfree = true; };

  # Clean up old generations after 30 days
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
