# Configuration for birne

{ self, ... }: {
  imports = [ ./hardware-configuration.nix ];

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  pinpox = {

    # Enable nextcloud configuration
    services.nextcloud.enable = true;

    server = {
      enable = true;
      hostname = "birne";

      homeConfig = {
        imports = [
          ../../home-manager/home-server.nix
          self.inputs.dotfiles-awesome.nixosModules.dotfiles
          {
            nixpkgs.overlays = [
              self.overlay
              self.inputs.nur.overlay
              self.inputs.neovim-nightly.overlay
            ];
          }
        ];
      };
    };

    services = {

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

        mega.authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW3f7nGeEDJIvu7LyLz/bWswPq9gR7AnC9vtiCmdG7C borg@mega"
        ];

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
  security.acme.email = "letsencrypt@pablo.tools";

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
