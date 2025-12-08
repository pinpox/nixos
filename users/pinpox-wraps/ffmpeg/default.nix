{ wlib, lib }:

wlib.wrapModule (
  {
    config,
    # wlib,
    ...
  }:
  {
    options = {
      profile = lib.mkOption {
        type = lib.types.enum [
          "fast"
          "quality"
        ];
        default = "fast";
        description = "Encoding profile to use";
      };
      outputDir = lib.mkOption {
        type = lib.types.str;
        default = "./output";
        description = "Directory for output files";
      };
    };

    config.package = config.pkgs.ffmpeg;
    config.flags = {
      "-preset" = if config.profile == "fast" then "veryfast" else "slow";
    };
    config.env = {
      FFMPEG_OUTPUT_DIR = config.outputDir;
    };
  }
)
