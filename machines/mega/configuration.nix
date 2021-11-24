{ self, ... }: {

  imports = [
    ./hardware-configuration.nix

    ## Note:
    ## If you use a custom nixpkgs version for evaluating your system,
    ## consider using `withLockedPkgs` instead of `withSystemPkgs` to use the exact
    ## pkgs versions for nix-bitcoin services that are tested by nix-bitcoin.
    ## The downsides are increased evaluation times and increased system
    ## closure size.
    #
    self.inputs.nix-bitcoin.nixosModules.withLockedPkgs
    # self.inputs.nix-bitcoin.nixosModules.withSystemPkgs

  ];

  nix-bitcoin.nodeinfo.enable = true;

  ## Optional:
  ## Import the secure-node preset, an opinionated config to enhance security
  ## and privacy.
  #
  # "${nix-bitcoin}/modules/presets/secure-node.nix"

  # Automatically generate all secrets required by services.
  # The secrets are stored in /etc/nix-bitcoin-secrets
  nix-bitcoin.generateSecrets = true;

  # Enable services.
  # See ../configuration.nix for all available features.
  services.bitcoind.enable = true;

  # When using nix-bitcoin as part of a larger NixOS configuration, set the following to enable
  # interactive access to nix-bitcoin features (like bitcoin-cli) for your system's main user
  nix-bitcoin.operator = {
    enable = true;
    name = "pinpox"; # Set this to your system's main user
  };

  nix-bitcoin.onionServices.spark-wallet.public = true;
  nix-bitcoin.onionServices.spark-wallet.enable = true;

    # spark-wallet.enable = defaultTrue;
  # nix-bitcoin.onionServices.spark-wallet.enable = true;



 # Set this to accounce the onion service address to peers.
  # The onion service allows accepting incoming connections via Tor.
  nix-bitcoin.onionServices.bitcoind.public = true;



 ### CLIGHTNING
  # Enable clightning, a Lightning Network implementation in C.
  services.clightning.enable = true;
  #
  # Set this to create an onion service by which clightning can accept incoming connections
  # via Tor.
  # The onion service is automatically announced to peers.
  nix-bitcoin.onionServices.clightning.public = true;
  #
  # == Plugins
  # See ../docs/usage.md for the list of available plugins.
  # services.clightning.plugins.prometheus.enable = true;


### RIDE THE LIGHTNING
  # Set this to enable RTL, a web interface for lnd and clightning.
  services.rtl.enable = true;
# services.lnd.enable = false;
  #
  # Set this to add a clightning node interface.
  # Automatically enables clightning.
  services.rtl.nodes.clightning = true;
  #
  # Set this to add a lnd node interface.
  # Automatically enables lnd.
  services.rtl.nodes.lnd = false;
  #
  # You can enable both nodes simultaneously.
  #
  # Set this option to enable swaps with lightning-loop.
  # Automatically enables lightning-loop.
  # services.rtl.loop = true;

  ### SPARK WALLET
  # Set this to enable spark-wallet, a minimalistic wallet GUI for
  # c-lightning, accessible over the web or through mobile and desktop apps.
  # Automatically enables clightning.
  services.spark-wallet.enable = true;




  pinpox = {

    server = {
      enable = true;
      hostname = "mega";
    };

    # wg-client = {
    #   enable = true;
    #   clientIp = "192.168.7.5";
    # };

    # services = {
    #   borg-backup.enable = true;
    #   go-karma-bot.enable = false;
    #   hedgedoc.enable = true;
    #   mattermost.enable = true;
    #   miniflux.enable = true;
    #   thelounge.enable = true;
    #   kf-homepage.enable = true;
    # };

    metrics.node.enable = true;
  };

  nix.autoOptimiseStore = true;

  programs.ssh.startAgent = false;

  services.qemuGuest.enable = true;

  # Setup Yubikey SSH and GPG
  services.pcscd.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # fileSystems."/tmp" = {
  #   fsType = "tmpfs";
  #   device = "tmpfs";
  #   options = [ "nosuid" "nodev" "relatime" "size=14G" ];
  # };

  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/sda";
  boot.loader.timeout = 0;

  # Block anything that is not HTTP(s) or SSH.
  # networking.firewall = {
  #   enable = true;
  #   allowPing = true;
  #   allowedTCPPorts = [ 80 443 22 ];
  # };
}
