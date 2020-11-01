{ nixpkgs ? <nixpkgs>, system ? "x86_64-linux" }:

let
  myconfig = { pkgs, ... }: {
    imports = [
      <nixpkgs/nixos/maintainers/scripts/openstack/openstack-image.nix>
    ];

    networking.hostName = "my-nix-host-3";

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


  environment.systemPackages = with pkgs; [
    tmux
    vim
  ];

  users.extraUsers.root.password = "root";
  users.extraUsers.p.password = "p";
};

evalNixos = configuration: import "${nixpkgs}/nixos" {
  inherit system configuration;
};

in {
  iso = (evalNixos myconfig).config.system.build.openstackImage;
}
