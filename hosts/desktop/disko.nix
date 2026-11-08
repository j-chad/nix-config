{
    disko.devices = {
        disk = {
            nixos = {
                type = "disk";
                device = "/dev/disk/by-id/nvme-WDC_WDS200T2B0C-00PXH0_21110P800356";
                content = {
                    type = "gpt";
                    partitions = {
                        ESP = {
                            size = "1G";
                            type = "EF00";
                            content = {
                                type = "filesystem";
                                format = "vfat";
                                mountpoint = "/boot";
                                mountOptions = [ "umask=0077" ];
                            };
                        };
                        root = {
                            size = "100%";
                            content = {
                                type = "btrfs";
                                extraArgs = [ "-L" "nixos" "-f" ];
                                postCreateHook = ''
                                    MNTPOINT=$(mktemp -d)
                                    mount "/dev/disk/by-label/nixos" "$MNTPOINT" -o subvol=/
                                    trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                                    btrfs subvolume snapshot -r $MNTPOINT/@root $MNTPOINT/@root-blank
                                    btrfs subvolume snapshot -r $MNTPOINT/@home $MNTPOINT/@home-blank
                                '';
                                subvolumes = {
                                    "@root" = {
                                        mountpoint = "/";
                                        mountOptions = [ "compress=zstd" "noatime" ];
                                    };
                                    "@home" = {
                                        mountpoint = "/home";
                                        mountOptions = [ "compress=zstd" "noatime" ];
                                    };
                                    "@nix" = {
                                        mountpoint = "/nix";
                                        mountOptions = [ "compress=zstd" "noatime" ];
                                    };
                                    "@persist" = {
                                        mountpoint = "/persist";
                                        mountOptions = [ "compress=zstd" "noatime" ];
                                    };
                                    "@log" = {
                                        mountpoint = "/var/log";
                                        mountOptions = [ "compress=zstd" "noatime" ];
                                    };
                                };
                            };
                        };
                    };
                };
            };
        };
    };

    fileSystems."/persist".neededForBoot = true;
    fileSystems."/var/log".neededForBoot = true;
}
