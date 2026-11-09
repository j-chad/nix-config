{ config, ... }:

let
  bwSshSocket = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";

  # Authentication public keys (private keys live in Bitwarden Vault)
  keys = {
    github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2vQorzVyieL2o68zFPBh0PzlUziI06lu1c7oLHpOcr";
    homelab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJTNZhXN5jf4TMcj8oYwgM/PxLGcVKRadaVNDI3zXxXT";
  };
in
{
  # Materialize public keys in ~/.ssh/ so OpenSSH can filter Bitwarden's agent keys
  home.file = {
    ".ssh/id_github.pub".text = "${keys.github}\n";
    ".ssh/id_homelab.pub".text = "${keys.homelab}\n";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        identityAgent = bwSshSocket;
        identitiesOnly = true;
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/id_github.pub";
      };

      # Example server/host using a different key in Bitwarden
      "homelab" = {
        hostname = "192.168.1.50";
        user = "jackson";
        identityFile = "${config.home.homeDirectory}/.ssh/id_homelab.pub";
      };
    };
  };
}
