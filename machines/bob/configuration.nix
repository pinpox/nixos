{ pkgs, mayniklas-keys, ... }: {

  imports = [ ./hardware-configuration.nix ];

  # Force non-default keyboard layout since this is a shared host
  console.keyMap = pkgs.lib.mkForce "de";

  lollypops.deployment.ssh.host = "drone.lounge.rocks";

  /* services.nginx = {
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

      # binary-cache.enable = true;
      droneci.enable = true;
      # droneci.runner-exec.enable = true;
      # droneci.runner-docker.enable = true;
      monitoring-server.http-irc.enable = true;
    };

    metrics.node.enable = true;
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [ mayniklas-keys ];

  networking = {
    # Open ports in the firewall.
    firewall.allowedTCPPorts = [
      80
      443
      9100 # Node exporter. Host is behind external firewall
    ];
  };

  # Workaround for problems with the dockerized CI
  systemd.enableUnifiedCgroupHierarchy = false;

}
