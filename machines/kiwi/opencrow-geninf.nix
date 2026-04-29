{
  distro,
  opencrow,
  pkgs,
  ...
}:
{
  imports = [
    opencrow.nixosModules.default
    distro.nixosModules.opencrow
    distro.nixosModules.llama-swap
  ];


  # Local LLM server
  services.llama-swap.enable = true;


  services.opencrow-local = {
    enable = true;
    instanceName = "geninf";
    piPackage = pkgs.pi;
    llmUrl = "http://127.0.0.1:8012";
    model = "qwen2.5:0.5b";
    socketName = "GenInf Crow";
    noctaliaPlugin = true;
    noctaliaPluginUsers = [ "pinpox" ];
    extraPackages = [
      pkgs.pi
      pkgs.curl
      pkgs.jq
    ];
  };
}
