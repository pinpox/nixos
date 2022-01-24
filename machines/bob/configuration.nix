# Configuration for bob
{ self, ... }:
{ pkgs, ... }: {

  imports = [ ./hardware-configuration.nix ];

  # Force non-default keyboard layout since this is a shared host
  console.keyMap = pkgs.lib.mkForce "de";

  /*

  services.nginx = {
    enable = true;
    virtualHosts = {
      "hydra.lounge.rocks" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:9876"; };
      };
    };
  };

  services.hydra = {
    enable = true;
    hydraURL = "https://hydra.lounge.rocks"; # externally visible URL
    notificationSender = "hydra@localhost"; # e-mail of hydra service
    port = 9876; # Default
    # a standalone hydra will require you to unset the buildMachinesFiles list to avoid using a nonexistant /etc/nix/machines
    buildMachinesFiles = [ ];
    # you will probably also want, otherwise *everything* will be built from scratch
    useSubstitutes = true;

    extraConfig = ''
      <hydra_notify>
        <prometheus>
          listen_address = 127.0.0.1
          port = 9199
        </prometheus>
      </hydra_notify>
      <runcommand>
        command = ${pkgs.coreutils}/bin/cat $HYDRA_JSON >> /tmp/test.log.json
      </runcommand>
    '';
  };

  # nix.allowedUsers = [ "hydra" ];
  nix.allowedUsers = [ "hydra" "hydra-queue-runner" "hydra-www" ];


  */

  pinpox = {
    server = {
      enable = true;
      hostname = "bob";
    };

    services = {

      # No backup from our side for this host.
      borg-backup.enable = false;

      binary-cache.enable = true;
      droneci.enable = true;
      droneci.runner-exec.enable = true;
      droneci.runner-docker.enable = true;
      monitoring-server.http-irc.enable = true;
    };

    metrics.node.enable = true;
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [
    (pkgs.fetchurl {
      url = "https://github.com/MayNiklas.keys";
      sha256 = "sha256:174dbx0kkrfdfdjswdny25nf7phgcb9k8i6z3rqqcy9l24f8xcp3";
    })
  ];

  boot = {

    # Enable arm emulation capabilities
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    growPartition = true;

    loader = {
      grub = {
        enable = true;
        version = 2;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
    };
    cleanTmpDir = true;
  };

  networking = {

    # DHCP
    useDHCP = false;
    interfaces.ens192.useDHCP = true;

    # Open ports in the firewall.
    firewall.allowedTCPPorts = [
      80
      443
      9100 # Node exporter. Host is behind external firewall
    ];

    # Make the host resolv the cache to itself
    extraHosts = ''
      127.0.0.1 cache.lounge.rocks
    '';
  };

  virtualisation.vmware.guest.enable = true;

  # Workaround for problems with the dockerized CI
  systemd.enableUnifiedCgroupHierarchy = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
