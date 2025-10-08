{
  _class = "clan.service";
  manifest.name = "machine-type";

  roles.server.perInstance.nixosModule = ./server.nix;
  roles.server.description = "Server machine settings, no GUI";
  roles.desktop.perInstance.nixosModule = ./desktop.nix;
  roles.desktop.description = "Desktop machine settings, including wayland and sway";

  # Common configuration for all macine types
  perMachine.nixosModule =
    { lib, ... }:
    {
      security.acme.acceptTerms = true;
      security.acme.defaults.email = lib.mkDefault "letsencrypt@pablo.tools";
      clan.core.settings.state-version.enable = true;
      hardware.enableRedistributableFirmware = true;
      pinpox.metrics.node.enable = true;
    };
}
