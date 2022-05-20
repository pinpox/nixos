{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.programs.tmux;
in
{
  options.pinpox.programs.tmux.enable =
    mkEnableOption "tmux terminal mutliplexer";

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      # Set the prefix key. Overrules the "shortcut" option when set.
      prefix = "C-a";

      # Automatically spawn a session if trying to attach and none are running.
      newSession = true;

      # Base index for windows and panes.
      baseIndex = 1;

      # Use 24 hour clock.
      clock24 = true;

      # Maximum number of lines held in window history.
      historyLimit = 8000;

      # Less command delay
      escapeTime = 20;

      # Set the $TERM variable.
      terminal = "screen-256color";

      extraConfig = ''

        # Set the emulator's title
        set -g set-titles on
        set -g set-titles-string "#W"

        # Forward focus events from emulator
        set -s focus-events on

        # Watch for activity
        setw -g monitor-activity on
        set -g activity-action none

        # Copy to real clipboard
        set -g set-clipboard on


        ####
        # Look and feel
        ####

        # 24 bit colors
        set -sa terminal-overrides ',xterm-256color*:Tc'

        # Status bar
        set -g status-style fg=white,bg=black,default
        set -g window-status-current-style fg=red
        set -gw window-status-activity-style bg=colour162,none

        # Make inactive panes grey
        setw -g window-style 'bg=#313547'
        setw -g window-active-style 'bg=black'
        setw -g pane-active-border-style ""

        # Pane border gray
        set -g pane-border-style fg=colour235
        set -g pane-active-border-style fg=yellow

        # Pane number display colors
        set -g display-panes-active-colour red
        set -g display-panes-colour blue
        set -g display-panes-time 500

        set -g status-left ""
        # Right status
        set -g status-right "\
          #[fg=colour231,bg=colour04]#{?client_prefix, ^A ,}#[default]\
          #[fg=colour231,bg=colour09]#{?pane_in_mode, Copy ,}#[default]\
          #[fg=colour002]#([ $(tmux show-option -qv key-table) = off ] && echo '(off) ')#[default]\
          #[default]#{?#(echo $IN_NIX_SHELL), (nix) ,}\
          #[default]#[fg=gray]$USER@#(hostname)"

        # Enable mouse support
        set -g mouse on


        ####
        # Keys
        ####
        # # Clients & Sessions
        # bind-key r source-file $HOME/.tmux.conf\; display "Reloaded"
        # # Windows & Panes
        # bind-key Space copy-mode
        # bind-key b break-pane
        # bind-key m join-pane -h
        # bind-key C-m join-pane
        # bind-key o last-pane
        # bind-key i last-window
        # bind-key c new-window -c "#{pane_current_path}"
        # bind-key -r C-h resize-pane -L
        # bind-key -r C-j resize-pane -D
        # bind-key -r C-k resize-pane -U
        # bind-key -r C-l resize-pane -R
        # bind-key . command-prompt "select-pane -t '%%'"

        # Select panes with hjkl instead of arrows
        unbind-key Left
        unbind-key Down
        unbind-key Up
        unbind-key Right
        bind-key h select-pane -L
        bind-key j select-pane -D
        bind-key k select-pane -U
        bind-key l select-pane -R

        # bind-key - split-window -c "#{pane_current_path}"
        # bind-key '|' split-window -h -c "#{pane_current_path}"
        # bind-key s swap-window
        # bind-key C-a send-prefix
        # bind-key a send-prefix
        # bind-key , select-pane -m
        # # Copy-mode
        # bind-key -T copy-mode-vi v send -X begin-selection
        # bind-key -T copy-mode-vi y send -X copy-selection
        #
        # set-option -g prefix C-a
        # # vi keys
        # setw -g mode-keys vi
        # set -g status-keys vi
        #
        # # Oof
        # bind -T root F11  \
        #   set prefix None \;\
        #   set key-table off \;\
        #   if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
        #   refresh-client -S \;\
        #
        # bind -T off F11 \
        #   set -u prefix \;\
        #   set -u key-table \;\
        #   refresh-client -S
        #
              '';

    };
  };
}
