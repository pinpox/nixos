inputs:
let
  # Pass flake inputs to overlay so we can use the sources pinned in flake.lock
  # instead of having to keep sha256 hashes in each package for src
  inherit inputs;
in
self: super: {

  ndi = super.ndi.overrideAttrs (old: {

    # Override unfree src with flake input and adapt unpackPhase
    # accordingly
    src = inputs.ndi-linux;
    unpackPhase = ''
      echo y | $src;
      sourceRoot="NDI SDK for Linux";
    '';

    # TODO Currently ndi is broken/outdated in nixpkgs.
    # Remove this installPhase when
    # https://github.com/NixOS/nixpkgs/pull/272073 is merged
    installPhase = with super;
      let
        ndiPlatform = "x86_64-linux-gnu";
        pname = "ndi";
        version = "5.6.0";
      in

      ''
        mkdir $out
        mv bin/${ndiPlatform} $out/bin
        for i in $out/bin/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$i"
        done
        patchelf --set-rpath "${avahi}/lib:${stdenv.cc.libc}/lib" $out/bin/ndi-record
        mv lib/${ndiPlatform} $out/lib
        for i in $out/lib/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-rpath "${avahi}/lib:${stdenv.cc.libc}/lib" "$i"
        done
        mv include examples $out/
        mkdir -p $out/share/doc/${pname}-${version}
        mv licenses $out/share/doc/${pname}-${version}/licenses
        mv documentation/* $out/share/doc/${pname}-${version}/
      '';
  });

  # Example package, used only for tests
  hello-custom =
    super.callPackage ../packages/hello-custom
      { };
  darktile = super.callPackage ../packages/darktile { };
  # river-luatile = super.callPackage ../packages/river-luatile { };
  fritzbox_exporter = super.callPackage ../packages/fritzbox_exporter { };
  mqtt2prometheus = super.callPackage ../packages/mqtt2prometheus { };

  # Custom packages. Will be made available on all machines and used where
  # needed.
  wezterm-bin = super.callPackage ../packages/wezterm-bin { };
  wezterm-nightly = super.callPackage ../packages/wezterm-nightly { };
  filebrowser = super.callPackage ../packages/filebrowser { };
  smartmon-script = super.callPackage ../packages/smartmon-script { };

  # Vim plugins, added inside existing pkgs.vimPlugins
  vimPlugins = super.vimPlugins // {
    indent-blankline-nvim-lua =
      super.callPackage ../packages/indent-blankline-nvim-lua {
        inputs = inputs;
      };
    zk-nvim = super.callPackage ../packages/zk-nvim { inputs = inputs; };
    nvim-fzf = super.callPackage ../packages/nvim-fzf { inputs = inputs; };
    nvim-cokeline =
      super.callPackage ../packages/nvim-cokeline { inputs = inputs; };
    fzf-lua = super.callPackage ../packages/fzf-lua { inputs = inputs; };
  };

  # ZSH plugins
  zsh-abbrev-alias =
    super.callPackage ../packages/zsh-abbrev-alias { inputs = inputs; };
  zsh-colored-man-pages =
    super.callPackage ../packages/zsh-colored-man-pages { inputs = inputs; };

  forgit = super.callPackage ../packages/forgit { inputs = inputs; };
  tfenv = super.callPackage ../packages/tfenv { inputs = inputs; };
}
