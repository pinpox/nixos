{
  _class = "clan.service";
  manifest.name = "machine-type";

  roles.server.perInstance.nixosModule = ./server.nix;
  roles.desktop.perInstance.nixosModule = ./desktop.nix;

  perMachine.nixosModule = {
    clan.core.settings.state-version.enable = true;
    hardware.enableRedistributableFirmware = true;
    pinpox.metrics.node.enable = true;
  };
}
