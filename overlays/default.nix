inputs: flake-self: pinpox-utils:
let
  # Pass flake inputs to overlay so we can use the sources pinned in flake.lock
  # instead of having to keep sha256 hashes in each package for src
  inherit inputs;

  # Pass flake itself, so we can build woodpecker-pipeline and manual
  inherit flake-self;
in
self: super: {

  manual = super.callPackage ../packages/manual {
    inherit inputs;
    inherit pinpox-utils;
    inherit flake-self;
  };

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

  # TODO remove when fixed upsteam
  zynaddsubfx = super.zynaddsubfx.overrideAttrs (old: {
    CXXFLAGS = [
      # GCC 13: error: 'uint8_t' does not name a type
      "-include cstdint"
    ];
  });

  # TODO: remove when AGE_ASKPASS support lands upstream (str4d/rage#617)
  rage = super.rage.overrideAttrs (old: {
    src = inputs.rage;
    cargoDeps = super.rustPlatform.fetchCargoVendor {
      pname = old.pname;
      version = old.version;
      src = inputs.rage;
      hash = "sha256-yshoG/U43e9RgYt+PlnaWpYzJFIneX/WYh64mSLSdvA=";
    };
  });

  # Lets several YubiKeys share one identity: absent serials are skipped
  # instead of prompting (and hanging non-interactive callers like clan).
  # TODO: remove once str4d/age-plugin-yubikey#229 is merged and released.
  # Set (not appended) so a doubly-applied overlay does not patch twice.
  age-plugin-yubikey = super.age-plugin-yubikey.overrideAttrs {
    patches = [ ./age-plugin-yubikey-skip-not-found.patch ];
  };

  # To override packages from master input do:
  # pamixer = inputs.nixpkgs-master.legacyPackages."${super.system}".pamixer;

  # intel-graphics-compiler =
  #   inputs.nixpkgs-master.legacyPackages."${super.system}".intel-graphics-compiler;

  # Override tpm2-pytss from master for all python versions
  # https://github.com/NixOS/nixpkgs/issues/417992
  # python3 = super.python3.override {
  #   packageOverrides = python-self: python-super: {
  #     tpm2-pytss = inputs.nixpkgs-master.legacyPackages."${super.system}".python3Packages.tpm2-pytss;
  #   };
  # };
  #

  inherit (inputs.llm-agents.packages.${super.stdenv.hostPlatform.system})
    pi
    openspec
    claude-code
    but
    # gitbutler
    omp
    ;

  # claude-desktop self-downloads generic-linux binaries at runtime (claude-code
  # CLI, uv) and execs them; run the app inside an FHS user namespace so their
  # hardcoded /lib64 interpreter path resolves without system-wide nix-ld.
  # TODO https://github.com/numtide/llm-agents.nix/pull/8629
  claude-desktop =
    let
      inner = inputs.llm-agents.packages.${super.stdenv.hostPlatform.system}.claude-desktop;
    in
    super.buildFHSEnv {
      name = "claude-desktop";
      targetPkgs = pkgs: [
        inner
        pkgs.stdenv.cc.cc.lib
        pkgs.libglvnd
        pkgs.mesa
        pkgs.libgbm
        pkgs.vulkan-loader
      ];
      runScript = "claude-desktop";
      extraInstallCommands = ''
        ln -s ${inner}/share $out/share
      '';
    };

  rio = (inputs.rio.packages.${super.stdenv.hostPlatform.system}.default).overrideAttrs {
    doCheck = false;
  };

  # TODO: Remove once merged upstream in nixpkgs
  groups-relay = super.callPackage ../packages/groups-relay { };

  # Example package, used only for tests
  hello-custom = super.callPackage ../packages/hello-custom { };
  # river-luatile = super.callPackage ../packages/river-luatile { };
  fritzbox_exporter = super.callPackage ../packages/fritzbox_exporter { };
  mqtt2prometheus = super.callPackage ../packages/mqtt2prometheus { };
  # Custom packages. Will be made available on all machines and used where
  # needed.
  smartmon-script = super.callPackage ../packages/smartmon-script { };
  noctalia-askpass = super.callPackage ../packages/noctalia-askpass { };
  machine-report = super.callPackage ../packages/machine-report { };
  config-hash = super.callPackage ../packages/config-hash { };

  # Builder for NixOS Incus VM images as a single package (metadata + qcow2),
  # with sshd + pinpox keys baked in. Passed by value to the @pinpox/incus
  # `localImages` setting. `pkgs.mkIncusVmImage { modules = [ ... ]; }`.
  mkIncusVmImage = super.callPackage ../packages/incus-vm-image {
    inherit (inputs) pinpox-keys;
  };

  # Use custom neovim in standalone flake
  pinpox-neovim = inputs.pinpox-neovim.packages.${super.stdenv.hostPlatform.system}.pinpox-neovim;

  # ZSH plugins
  zsh-abbrev-alias = super.callPackage ../packages/zsh-abbrev-alias { inputs = inputs; };
  zsh-colored-man-pages = super.callPackage ../packages/zsh-colored-man-pages { inputs = inputs; };
  zsh-async = super.callPackage ../packages/zsh-async { inputs = inputs; };

}
