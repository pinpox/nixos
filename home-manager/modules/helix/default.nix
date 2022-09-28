{ lib
, config
, pkgs
, # helix, 
  colorscheme
, ...
}:
with lib;
let cfg = config.pinpox.programs.helix;
in
{
  options.pinpox.programs.helix.enable =
    mkEnableOption "helix editor";

  config = mkIf cfg.enable {


    home.packages = with pkgs; [
      rnix-lsp
      taplo
    ];



    programs.helix = {
      enable = true;

      # package = helix.default;

      # https://docs.helix-editor.com/languages.html 
      # languages = [ { auto-format = false; name = "rust"; } ];


      # https://docs.helix-editor.com/configuration.html f
      settings = {

        theme = "nix-generated";


        editor = {
          line-number = "relative";
          mouse = false;

          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          file-picker = {
            hidden = false;
          };
        };

        keys.normal =
          {
            # Swap ; and :
            ";" = "command_mode";
            ":" = "collapse_selection";

            # Use {} to walk paragraphs
            "{" = "goto_prev_paragraph";
            "}" = "goto_next_paragraph";
          };
      };

      # https://docs.helix-editor.com/themes.html 
      themes = {

        nix-generated = with colorscheme;
          {
            "ui.menu" = "note"; # Transparent
            "ui.menu.selected" = {
              modifiers = [ "reversed" ];
            };
            "ui.linenr" = { fg = Grey; bg = DarkGrey; };
            "ui.popup" = { modifiers = [ "reversed" ]; };
            "ui.linenr.selected" = { fg = White; bg = Black; modifiers = [ "bold" ]; };
            "ui.selection" = { fg = Black; bg = Blue; };
            "ui.selection.primary" = { modifiers = [ "reversed" ]; };
            "comment" = { fg = Grey; };
            "ui.statusline" = { fg = White; bg = DarkGrey; };
            "ui.statusline.inactive" = { fg = DarkGrey; bg = White; };
            "ui.help" = { fg = DarkGrey; bg = White; };
            "ui.cursor" = { modifiers = [ "reversed" ]; };
            "variable" = Red;
            "variable.builtin" = DarkYellow;
            "constant.numeric" = DarkYellow;
            "constant" = DarkYellow;
            "attributes" = Yellow;
            "type" = Yellow;
            "ui.cursor.match" = { fg = Yellow; modifiers = [ "underlined" ]; };
            "string" = Green;
            "variable.other.member" = Red;
            "constant.character.escape" = Cyan;
            "function" = Blue;
            "constructor" = Blue;
            "special" = Blue;
            "keyword" = Magenta;
            "label" = Magenta;
            "namespace" = Blue;
            "diff.plus" = Green;
            "diff.delta" = Yellow;
            "diff.minus" = Red;
            "diagnostic" = { modifiers = [ "underlined" ]; };
            "ui.gutter" = { bg = Black; };
            "info" = Blue;
            "hint" = DarkGrey;
            "debug" = DarkGrey;
            "warning" = Yellow;
            "error" = Red;
          };

      };
    };
  };
}
