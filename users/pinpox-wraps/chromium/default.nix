{ wlib, lib }:

{
  apply =
    {
      pkgs,
      extensions ? [ ],
      profileName ? "wrapped",
      ...
    }:
    let
      # Normalize extensions to ensure updateUrl is present
      normalizedExtensions = map (
        ext:
        ext
        // {
          updateUrl = ext.updateUrl or "https://clients2.google.com/service/update2/crx";
        }
      ) extensions;

      # Create extension JSON files
      extensionFiles = map (ext: {
        name = "External Extensions/${ext.id}.json";
        path = pkgs.writeText "${ext.id}.json" (builtins.toJSON { external_update_url = ext.updateUrl; });
      }) normalizedExtensions;

      # Create config directory template with extension settings
      extensionsDir = pkgs.linkFarm "chromium-extensions" extensionFiles;

      preHookScript = ''
        PROFILE_DIR="$HOME/.config/chromium-${profileName}"
        EXT_DIR="$PROFILE_DIR/External Extensions"

        # Create profile directory
        mkdir -p "$EXT_DIR"

        # Symlink extension configs from Nix store
        ${lib.concatMapStringsSep "\n" (ext: ''
          ln -sf "${extensionsDir}/External Extensions/${ext.id}.json" "$EXT_DIR/${ext.id}.json"
        '') normalizedExtensions}
      '';

      wrappedChromium = wlib.wrapPackage {
        inherit pkgs;
        package = pkgs.chromium;
        binName = "chromium-wrapped";
        preHook = preHookScript;
        flagSeparator = "=";
        flags."--user-data-dir" = "$HOME/.config/chromium-${profileName}";
      };
    in
    {
      wrapper = wrappedChromium;
    };
}
