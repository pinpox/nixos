{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.ntfy-notify;
in
{
  options.pinpox.services.ntfy-notify.enable = mkEnableOption "ntfy notifications via notify-send";

  config = mkIf cfg.enable {


    lollypops.secrets.files."ntfy-envfile" = { };

    systemd.user.services =
      let

        ntfy-config = pkgs.writeTextFile {
          name = "ntfy-client.json";
          text = builtins.toJSON
            {
              default-host = "https://push.pablo.tools";
              default-command = ''
                echo $raw
                ${pkgs.libnotify}/bin/notify-send "$title" "$m"
              '';
              subscribe = [
                { topic = "pinpox_backups"; }
                { topic = "pinpox_alertmanager"; }
              ];
            };
        };
      in

      {
        service-name = {
          Unit = {
            Description = "ntfy.sh desktop notifications";
            After = "network.target";
          };

          Service = {
            ExecStart = ''
              ${pkgs.ntfy-sh}/bin/ntfy subscribe -u $NTFY_USER:$NTFY_PASS --config=${ntfy-config} --from-config
            '';

            Environment = [
              "PATH=${pkgs.bash}/bin:/run/wrappers/bin"
              "DISPLAY=:0"
            ];

            EnvironmentFile = [ config.lollypops.secrets.files."ntfy-envfile".path ];
            Restart = "on-failure";
          };
        };
      };
  };
}
