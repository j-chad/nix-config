{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./system.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.jackson = import ../../home/jackson;
  };
}
