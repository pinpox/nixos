{ config, pkgs, lib, ... }: {

  networking = {

    # Defile the DNS servers
    nameservers = [ "1.1.1.1" "8.8.8.8" "192.168.2.1" ];

    # Enables wireless support via wpa_supplicant.
    # networking.wireless.enable = true;

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    # useDHCP = false;
    # interfaces.eno1.useDHCP = true;

    # Enable networkmanager
    networkmanager.enable = true;

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Additional hosts to put in /etc/hosts
    extraHosts = ''
      94.16.114.42 nix.own
      94.16.114.42 lislon.nix.own
      192.168.2.84 backup-server
      192.168.2.84 cloud.pablo.tools

      10.10.10.212 bucket.htb
      10.10.10.212 s3.bucket.htb
    '';
  };
}
