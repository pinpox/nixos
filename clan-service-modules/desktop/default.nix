{
  _class = "clan.service";
  manifest.name = "desktop";
  manifest.readme = "Desktop environment/wayland compositor setup";

  roles = {

    sway = {
      perInstance.nixosModule = ./sway.nix;
      description = "Sway (wayland): Minimalist tiling window manager with Wayland compositor support";
    };

    kde = {
      perInstance.nixosModule = ./kde.nix;
      description = "KDE/Plasma (wayland): Full-featured desktop environment with modern Qt-based interface";
    };
  };
}
