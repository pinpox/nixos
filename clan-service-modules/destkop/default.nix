{
  _class = "clan.service";
  manifest.name = "desktop";

  roles = {

    sway = {
      perInstance.nixosModule = ./sway.nix;
      description = "Sway tiling compositor (wayland)";
    };

    kde = {
      perInstance.nixosModule = ./kde.nix;
      description = "KDE Plasma";
    };

  };

  # Common configuration for all macine types
  perMachine.nixosModule =
    {
      # lib,
      ...
    }:
    {

      # TODO
      # security.acme.acceptTerms = true;
      # security.acme.defaults.email = lib.mkDefault "letsencrypt@pablo.tools";
      # clan.core.settings.state-version.enable = true;

    };
}
