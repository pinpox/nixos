{ nixpkgs ? <nixpkgs>, system ? "x86_64-linux" }:

let
  myisoconfig = { pkgs, ... }: {
    imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix" ];

    networking.hostName = "my-nix-host-2";

    # Set localization properties and timezone
    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "colemak";
    };

    time.timeZone = "Europe/Berlin";

    # Put all the stuff I want running in my instance here
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."example.com" = {
        # enableACME = true;
        # forceSSL = true;
        locations."/".root = "${pkgs.nginx}/html";
      };
    };

    environment.systemPackages = with pkgs; [ tmux vim ];

    users.extraUsers.root.password = "root";
  };

  evalNixos = configuration:
    import "${nixpkgs}/nixos" { inherit system configuration; };

in { iso = (evalNixos myisoconfig).config.system.build.isoImage; }

