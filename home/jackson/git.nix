{ config, ... }:

let
  gitEmail = "contact@jacksonc.dev";
  signingPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2vQorzVyieL2o68zFPBh0PzlUziI06lu1c7oLHpOcr";
  signingKeyPath = "${config.home.homeDirectory}/.ssh/id_git_signing.pub";
  allowedSignersPath = "${config.home.homeDirectory}/.ssh/allowed_signers";
in
{
  # Dedicated signing public key + allowed_signers for local `git log --show-signature`
  home.file = {
    ".ssh/id_git_signing.pub".text = "${signingPubKey}\n";
    ".ssh/allowed_signers".text = "${gitEmail} ${signingPubKey}\n";
  };

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Jackson Chadfield";
        email = gitEmail;
      };
      init.defaultBranch = "main";
      gpg.ssh.allowedSignersFile = allowedSignersPath;
    };

    signing = {
      format = "ssh";
      key = signingKeyPath;
      signByDefault = true;
    };
  };
}
