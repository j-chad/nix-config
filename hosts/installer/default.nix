{ config, pkgs, lib, modulesPath, self, disko, ... }:

let
  installDesktop = pkgs.writeShellApplication {
    name = "install-desktop";
    runtimeInputs = with pkgs; [
      git
      gh
      disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
      nixos-install-tools
      coreutils
      util-linux
    ];
    text = ''
      set -euo pipefail

      WORKDIR="/tmp/nix-config"
      TARGET_DIR="/mnt/home/jackson/code/personal/nix-config"

      echo "===================================================="
      echo "  NixOS Desktop Installer (j-desktop)"
      echo "===================================================="

      # 1. Stage the embedded flake snapshot into a writable directory
      rm -rf "$WORKDIR"
      cp -r /etc/nix-config "$WORKDIR"
      chmod -R u+w "$WORKDIR"

      # 2. Optionally fetch latest commits from private GitHub repo
      read -r -p "Fetch latest config updates from private GitHub repo via 'gh'? [y/N]: " fetch_latest
      if [[ "$fetch_latest" =~ ^[Yy]$ ]]; then
        if ! gh auth status >/dev/null 2>&1; then
          echo "-> Authenticating with GitHub CLI (Device Flow)..."
          gh auth login -h github.com -p https -w
        fi
        echo "-> Cloning latest j-chad/nix-config from GitHub..."
        rm -rf "$WORKDIR"
        gh repo clone j-chad/nix-config "$WORKDIR"
      else
        echo "-> Using embedded config snapshot from ISO (/etc/nix-config)."
      fi

      # 3. Confirm destructive Disko operation
      echo ""
      echo "WARNING: This will format the NixOS NVMe drive defined in:"
      echo "  $WORKDIR/hosts/desktop/disko.nix"
      lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
      echo ""
      read -r -p "Type 'FORMAT' to partition and mount the NixOS drive: " confirm
      if [[ "$confirm" != "FORMAT" ]]; then
        echo "Aborted."
        exit 1
      fi

      # 4. Run Disko to partition, format, create blank snapshots, and mount /mnt
      sudo disko --mode destroy,format,mount "$WORKDIR/hosts/desktop/disko.nix"

      # 5. Copy the config into jackson's home directory on the new system
      echo "-> Copying nix-config into $TARGET_DIR..."
      sudo mkdir -p "$(dirname "$TARGET_DIR")"
      sudo cp -r "$WORKDIR" "$TARGET_DIR"
      # Configure SSH remote URL ready for Bitwarden SSH Agent after first boot
      sudo git -C "$TARGET_DIR" remote set-url origin git@github.com:j-chad/nix-config.git 2>/dev/null || true
      sudo chown -R 1000:100 /mnt/home/jackson

      # 6. Install NixOS
      echo "-> Running nixos-install for .#desktop..."
      sudo nixos-install --flake "$TARGET_DIR#desktop" --no-root-passwd

      echo "===================================================="
      echo "  Installation complete! You can now run: reboot"
      echo "  On first boot, log in with initialPassword and"
      echo "  immediately run 'passwd' to set your real password."
      echo "===================================================="
    '';
  };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Embed a read-only copy of this flake repository right inside the ISO
  environment.etc."nix-config".source = self;

  # Include the install-desktop wizard and useful recovery tools
  environment.systemPackages = with pkgs; [
    installDesktop
    git
    gh
    vim
    btrfs-progs
    disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
  ];

  # Enable SSH in the installer for optional headless/remote installs
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = [
    # Optional: add your laptop/other machine's public key here for remote SSH into the ISO
  ];

  services.getty.helpLine = ''

    =======================================================================
    Custom NixOS Installer for j-desktop
    Run `sudo install-desktop` to partition (Disko) and install NixOS!
    =======================================================================
  '';

  system.stateVersion = "26.05";
}
