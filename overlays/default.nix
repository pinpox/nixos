inputs: flake-self:
let
  # Pass flake inputs to overlay so we can use the sources pinned in flake.lock
  # instead of having to keep sha256 hashes in each package for src
  inherit inputs;

  # Pass flake itself, so we can build woodpecker-pipeline and manual
  inherit flake-self;
in
self: super: {

  # TODO: fix infinite recursion
  manual = super.callPackage ../packages/manual {
    inherit inputs;
    flake-self.nixosModules = with flake-self.nixosModules; {

      # TODO:
      # Some modules cause infinite recursion, so we only pass the ones that
      # work. There is probably a better way, this should be automagic.

      # caddy-security = flake-self.nixosModules.caddy-security;

      inherit
        activation-secrets
        bluetooth
        ci
        default-desktop
        default-server
        dex
        ente
        environment
        fonts
        gitea
        hedgedoc
        hello
        home-assistant
        http2irc
        kf-homepage
        locale
        lvm-grub
        miniflux
        minio
        monitoring
        networking
        nextcloud
        nix-common
        ntfy-sh
        openssh
        owncast
        restic
        sound
        thelounge
        unbound-desktop
        vikunja
        virtualisation
        wastebin
        wireguard-client
        yubikey
        zsh
        ;
    };
  };

  # TODO workaround for
  # https://github.com/nix-community/home-manager/issues/5991, remove when
  # merged
  utillinux = super.util-linux;

  woodpecker-pipeline = super.callPackage ../packages/woodpecker-pipeline {
    inherit inputs;
    inherit flake-self;
  };

  # Override unfree src with flake input
  # ndi = super.ndi.overrideAttrs (old: {
  #   src = inputs.ndi-linux;
  #   unpackPhase = ''
  #     echo y | $src;
  #     sourceRoot="NDI SDK for Linux";
  #   '';
  # });

  # museum = super.callPackage ../packages/ente/museum.nix { };
  ente-web = super.callPackage ../packages/ente/web.nix { };

  # TODO remove when fixed upsteam
  zynaddsubfx = super.zynaddsubfx.overrideAttrs (old: {
    CXXFLAGS = [
      # GCC 13: error: 'uint8_t' does not name a type
      "-include cstdint"
    ];
  });

  # Example package, used only for tests
  hello-custom = super.callPackage ../packages/hello-custom { };
  # river-luatile = super.callPackage ../packages/river-luatile { };
  fritzbox_exporter = super.callPackage ../packages/fritzbox_exporter { };
  mqtt2prometheus = super.callPackage ../packages/mqtt2prometheus { };

  # Custom packages. Will be made available on all machines and used where
  # needed.
  smartmon-script = super.callPackage ../packages/smartmon-script { };

  # Use custom neovim in standalone flake
  neovim = inputs.pinpox-neovim.packages.x86_64-linux.pinpox-neovim;

  # ZSH plugins
  zsh-abbrev-alias = super.callPackage ../packages/zsh-abbrev-alias { inputs = inputs; };
  zsh-colored-man-pages = super.callPackage ../packages/zsh-colored-man-pages { inputs = inputs; };

  forgit = super.callPackage ../packages/forgit { inputs = inputs; };
}
