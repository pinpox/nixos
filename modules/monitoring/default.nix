{ pkgs, config, ... }:

{
  imports = [ ./metrics.nix ./grafana.nix ./loki.nix ./prometheus.nix ];
}
