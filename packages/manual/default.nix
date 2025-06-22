{
  stdenvNoCC,
  pkgs,
  flake-self,
  inputs,
  pinpox-utils,
}:

stdenvNoCC.mkDerivation rec {
  pname = "flake-manual";
  version = "latest";
  src = ./.;
  dontConfigure = true;
  dontUnpack = true;

  buildPhase =

    let
      options-json =
        let

          isValidOpt = a: (builtins.hasAttr "_type" a) && (a._type == "option");

          getOptionValues =
            opt: path:
            if builtins.typeOf opt == "set" then
              if isValidOpt opt then
                {
                  inherit path;
                  name = builtins.concatStringsSep "." path;
                  example = if builtins.hasAttr "example" opt then opt.example else "";
                  description = if builtins.hasAttr "description" opt then opt.description else "";
                  default =
                    if builtins.hasAttr "defaultText" opt then
                      opt.defaultText
                    else
                      let
                        defaultEval = builtins.tryEval (if builtins.hasAttr "default" opt then opt.default else "");
                      in
                      if defaultEval.success then defaultEval.value else "<evaluation failed>";
                  type = opt.type.description;
                  documentedOption = true;
                }
              else
                # it is a set, but has no "default", recurse
                builtins.mapAttrs (name: value: getOptionValues value (path ++ [ "${name}" ])) opt
            else
              { }; # it is no set
        in
        pkgs.writeTextFile {
          name = "options.json";
          text = builtins.toJSON {
            options = pkgs.lib.attrsets.collect (o: o ? "documentedOption") (
              pkgs.lib.attrsets.mapAttrs (
                name: value:
                let
                  allopts = getOptionValues (value (
                    {
                      inherit (inputs) flake-self;
                      inherit pkgs;
                      inherit pinpox-utils;
                      lib = pkgs.lib;
                      config = { };
                    }
                    // inputs
                  )) [ ];
                in
                if
                  # Filter out everything that has no ".options.pinpox"
                  builtins.hasAttr "options" allopts
                then
                  if builtins.hasAttr "pinpox" allopts.options then allopts.options.pinpox else null
                else
                  null
              ) flake-self.nixosModules
            );
          };
        };
    in
    ''
      cat ${options-json} | ${pkgs.mustache-go}/bin/mustache --allow-missing-variables=false ${src}/template.html > index.html
    '';

  installPhase = ''
    mkdir -p "$out"
    cp index.html "$out"
  '';

  meta = {
    description = "Manual for this flake as package";
    homepage = "https://github.com/pinpox/nixos";
  };
}
