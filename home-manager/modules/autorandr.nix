{ config, pkgs, lib, ... }: {

  programs.autorandr = {
    enable = true;
    profiles = {
      "home-kartoffel" = {
        fingerprint = {

          DP-0 = (builtins.replaceStrings [ "\n" ] [ "" ] ''
            00ffffffffffff00410cf508316c0000261e0104a5371f783a4455a9554d9d260f50
            54bd4b00d1c081808140950f9500b30081c00101565e00a0a0a02950302035002937
            2100001e000000ff0055484232303338303237363937000000fc0050484c20323538
            423651550a20000000fd00174c0f631e010a2020202020200187020318f44b010203
            040590111213141f2309070783010000023a80d072382d40102c9680293721000018
            023a801871382d40582c9600293721000018283c80a070b023403020360029372100
            001a011d00bc52d01e20b828554029372100001e8c0ad090204031200c4055002937
            21000018000000000000000000000000005c'');

          DVI-D-1 = (builtins.replaceStrings [ "\n" ] [ "" ] ''
            00ffffffffffff0022649189070400001610010380291a782a9bb6a4534b9d24144f5
            4bfef0031466146714f814081809500950f01019a29a0d0518422305098360098ff10
            00001c000000fd00314b1e500e000a202020202020000000fc004857313931440a202
            020202020000000ff00363232474833324341313033310024'');

          HDMI-0 = (builtins.replaceStrings [ "\n" ] [ "" ] ''
            00ffffffffffff004c2d87053432594d2a130103803420782aee91a3544c99260f505
            4230800a9408180814081009500b30001010101283c80a070b0234030203600064421
            00001a000000fd00323f1e5111000a202020202020000000fc0053796e634d6173746
            5720a2020000000ff00483958534130353934340a2020019102010400023a80187138
            2d40582c450006442100001e023a80d072382d40102c458006442100001e011d00725
            1d01e206e28550006442100001e011d00bc52d01e20b828554006442100001e8c0ad0
            90204031200c4055000644210000188c0ad08a20e02d10103e9600064421000018000
            00000000000000000000000000096'');
        };
        config = {

          DVI-D-0.enable = false;
          DP-1.enable = false;

          DP-0 = {
            enable = true;
            mode = "2560x1440";
            crtc = 0;
            position = "900x0";
            rate = "60.00";
            primary = true;
            # dpi = 96;
          };

          DVI-D-1 = {
            enable = true;
            crtc = 2;
            mode = "1440x900";
            position = "0x0";
            rotate = "right";
            rate = "60.00";
          };

          HDMI-0 = {
            enable = true;
            crtc = 1;
            mode = "1920x1200";
            position = "3460x64";
            rate = "60.00";
          };
        };
      };
    };
    # hooks = {
    #   postswitch = {
    # "notify-i3" = "${pkgs.i3}/bin/i3-msg restart";
    # "change-background" = readFile ./change-background.sh;
    # "change-dpi" = ''
    #   case "$AUTORANDR_CURRENT_PROFILE" in
    #     default)
    #       DPI=120
    #       ;;
    #     home)
    #       DPI=192
    #       ;;
    #     work)
    #       DPI=144
    #       ;;
    #     *)
    #       echo "Unknown profle: $AUTORANDR_CURRENT_PROFILE"
    #       exit 1
    #   esac
    #   echo "Xft.dpi: $DPI" | ${pkgs.xorg.xrdb}/bin/xrdb -merge
    # ''
    # };
    # };
  };
}
