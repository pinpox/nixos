# { lib, stdenv, buildGoModule, fetchFromGitHub }:

# buildGoModule rec {
#   pname = "drone-runner-exec";
#   version = "2020-04-19";

#   src = fetchFromGitHub {
#     owner = "drone-runners";
#     repo = "drone-runner-exec";
#     rev = "c0a612ef2bdfdc6d261dfbbbb005c887a0c3668d";
#     sha256 = "sha256-0UIJwpC5Y2TQqyZf6C6neICYBZdLQBWAZ8/K1l6KVRs=";
#   };

#   vendorSha256 = "sha256-ypYuQKxRhRQGX1HtaWt6F6BD9vBpD8AJwx/4esLrJsw=";

#   meta = with lib; {
#     description =
#       "Drone pipeline runner that executes builds directly on the host machine";
#     homepage = "https://github.com/drone-runners/drone-runner-exec";
#     # https://polyformproject.org/licenses/small-business/1.0.0/
#     license = licenses.unfree;
#   };
# }


{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.drone-runner-exec;
in {

  options.pinpox.services.monitoring-server = {
    enable = mkEnableOption "DroneCI exec runner";
    # nodeTargets = mkOption {
    #   type = types.listOf types.str;
    #   default = [ "porree.wireguard:9100" ];
    #   example = [ "hostname.wireguard:9100" ];
    #   description = "Targets to monitor with the node-exporter";
    # };
  };

  config = mkIf cfg.enable {

    services.prometheus = {
    };
  };
}
