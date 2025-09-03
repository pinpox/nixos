{
  _class = "clan.service";
  manifest.name = "machine-type";

  roles.server.perInstance.nixosModule = ./server.nix;
  roles.desktop.perInstance.nixosModule = ./desktop.nix;

  # Common configuration for all macine types
  perMachine.nixosModule = {lib, ...}: {
    security.acme.defaults.email = lib.mkDefault "letsencrypt@pablo.tools";
    clan.core.settings.state-version.enable = true;
    hardware.enableRedistributableFirmware = true;
    pinpox.metrics.node.enable = true;
  };
}
