{ pkgs, config, ... }:

{
  imports = [
    ./server.nix
    ./drone-runner-docker.nix
    # ./exec-runner.nix
    # ./ssh-runner.nix
  ];
}
