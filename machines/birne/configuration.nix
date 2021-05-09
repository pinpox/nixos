# Configuration for birne

{ self, ... }: {
  imports = [ ./hardware-configuration.nix ];

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  pinpox = {

    services.filebrowser.enable = true;

    server = {
      enable = true;
      hostname = "birne";

      homeConfig = {

        imports = [
          ../../home-manager/home-server.nix
          self.inputs.dotfiles-awesome.nixosModules.dotfiles
          {
            nixpkgs.overlays =
              [ self.inputs.nur.overlay self.inputs.neovim-nightly.overlay ];
          }
        ];
      };
    };

    services = {
      borg-server.enable = true;
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
