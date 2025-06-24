{
  # Nextcloud on the desktop
  services.davfs2 = {
    enable = true;
    # settings.globalSection.use_locks = false;
    #     TODO: Note: Ordinary users can mount a davfs2 file system if they are a
    #     member of the group dav_group as defined in the system wide
    #     configuration. Make sure the option 'dav_group' is enabled in the system
    #     wide configuration file.
  };
  # fileSystems."/home/pinpox/Nextcloud" = {
  #   device = "https://files.pablo.tools/remote.php/dav/files/pinpox";
  #   fsType = "davfs";
  #   options = [
  #     "user"
  #     "rw"
  #     "noauto" # I'll mount it manually
  #   ];
  # };
}
