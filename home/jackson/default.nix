{ pkgs, ... }:

{
  imports = [
    ./bitwarden.nix
    ./ssh.nix
    ./git.nix
    ./firefox.nix
  ];

  home.username = "jackson";
  home.homeDirectory = "/home/jackson";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
