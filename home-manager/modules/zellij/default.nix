{
  lib,
  pkgs,
  config,
  flake-inputs,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.zellij;

  # Sidebar grouping tabs by project; names tabs project:workspace and manages
  # jj workspaces / git worktrees (Alt w / Alt W). The same package ships the
  # `zellij-ws` CLI for scripts and agents, and the Agent Skill documenting it.
  workspaces =
    flake-inputs.zellij-workspaces.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.pinpox.programs.zellij.enable = mkEnableOption "zellij terminal mutliplexer";

  config = mkIf cfg.enable {
    programs.zellij = {

      enable = true;

      # Don't auto-start zellij on new shells
      enableZshIntegration = false;

      # New tabs copy this layout, so every tab gets the tab bar (the tabs of
      # the current session, i.e. workspace) and the sidebar. The plugin is
      # loaded from a stable path (symlink below): zellij keys granted
      # permissions by that path, so they survive plugin updates.
      layouts.workspaces = ''
        layout {
            pane size=1 borderless=true {
                plugin location="zellij:tab-bar"
            }
            pane split_direction="vertical" {
                pane size=28 borderless=true {
                    plugin location="file:~/.config/zellij/plugins/zellij-workspaces.wasm"
                }
                pane
            }
            pane size=1 borderless=true {
                plugin location="zellij:status-bar"
            }
        }
      '';

      settings = {

        keybinds.unbind = "Ctrl q";

        default_layout = "workspaces";
        session_serialization = false;
        show_startup_tips = false;
        simplified_ui = true;

        # 0.45.0+ enters Scroll mode on mouse scroll-up, so typing hits
        # scroll-mode bindings (e.g. `s` = search). Restore the old behaviour:
        # stay in Normal mode, typing snaps back to the bottom.
        scroll_mode_sync = false;

        theme = "custom";
        themes.custom = {
          fg = "#${config.pinpox.colors.White}";
          bg = "#${config.pinpox.colors.BrightBlack}";
          black = "#${config.pinpox.colors.Black}";
          red = "#${config.pinpox.colors.Red}";
          green = "#${config.pinpox.colors.Green}";
          yellow = "#${config.pinpox.colors.BrightYellow}";
          blue = "#${config.pinpox.colors.Blue}";
          magenta = "#${config.pinpox.colors.Magenta}";
          cyan = "#${config.pinpox.colors.Cyan}";
          white = "#${config.pinpox.colors.White}";
          orange = "#${config.pinpox.colors.Yellow}";
        };
      };
    };

    xdg.configFile."zellij/plugins/zellij-workspaces.wasm".source =
      "${workspaces}/share/zellij/plugins/zellij-workspaces.wasm";

    home.packages = [ workspaces ];

    # Agent skill for zellij-ws, offered to every enabled harness.
    pinpox.agentSkills = [ workspaces ];
  };
}
