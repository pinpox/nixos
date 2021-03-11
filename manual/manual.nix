with import <nixpkgs> { };
let
  eval = import (pkgs.path + "/nixos/lib/eval-config.nix") {
    modules = [ ./hello.nix ../modules/wireguard-client.nix ];
  };
  opts = (nixosOptionsDoc { options = eval.options; }).optionsJSON;

  templateMarkdown = pkgs.writeTextFile {
    name = "markdown";
    text = builtins.readFile ./templates/markdown.mustache;
  };


  templateHTML = pkgs.writeTextFile {
    name = "html";
    text = builtins.readFile ./templates/html.mustache;
  };

in rec {



  json = runCommandLocal "options.json" { inherit opts; } ''
    cat $opts/share/doc/nixos/options.json | \
    ${pkgs.jq}/bin/jq '.| with_entries( select(.key|contains("pinpox") ) )' \
    > $out
  '';

  markdown = runCommandLocal "options.md" { inherit opts; } ''
    cat $opts/share/doc/nixos/options.json | \
    ${pkgs.jq}/bin/jq '.| with_entries( select(.key|contains("pinpox") ) ) | [to_entries[]] | {options: .}' | \
    ${pkgs.mustache-go}/bin/mustache ${templateMarkdown} \
    > $out
    '';

  html = runCommandLocal "options.md" { inherit opts; } ''
    cat $opts/share/doc/nixos/options.json | \
    ${pkgs.jq}/bin/jq '.| with_entries( select(.key|contains("pinpox") ) ) | [to_entries[]] | {options: .}' | \
    ${pkgs.mustache-go}/bin/mustache ${templateHTML} \
    > $out
    '';

}



# cat data.json| jq '[to_entries[]] | {options: .}' | ~/.go/bin/mustache html.mustache
