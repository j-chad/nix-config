{ config, pkgs, ... }:

let
  bwSshSocket = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
in
{
  home.packages = with pkgs; [
    bitwarden-desktop
  ];

  # Expose Bitwarden SSH agent socket to shells and systemd/GNOME user session
  home.sessionVariables.SSH_AUTH_SOCK = bwSshSocket;
  systemd.user.sessionVariables.SSH_AUTH_SOCK = bwSshSocket;
}
