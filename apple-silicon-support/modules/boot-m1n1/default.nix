{ config, pkgs, lib, ... }:
let
  bootFiles = {
    "m1n1/boot.bin" = pkgs.runCommand "boot.bin" {} ''
      cat ${config.boot.loader.asahi.m1n1.package}/build/m1n1.bin > $out
      cat ${config.boot.kernelPackages.kernel}/dtbs/apple/*.dtb >> $out
      cat ${config.boot.loader.asahi.uboot.package}/u-boot-nodtb.bin.gz >> $out
      if [ -n "${config.boot.loader.asahi.m1n1.extraOptions}" ]; then
        echo '${config.boot.loader.asahi.m1n1.extraOptions}' >> $out
      fi
    '';
  };
in {
  config = lib.mkIf config.hardware.asahi.enable {
    # install m1n1 with the boot loader
    boot.loader.grub.extraFiles = bootFiles;
    boot.loader.systemd-boot.extraFiles = bootFiles;

    # ensure the installer has m1n1 in the image
    system.extraDependencies = lib.mkForce [
      config.boot.loader.asahi.m1n1.package
      config.boot.loader.asahi.uboot.package
    ];

    system.build.m1n1 = bootFiles."m1n1/boot.bin";
  };

  imports = [
    (lib.mkRenamedOptionModule [ "boot" "m1n1ExtraOptions" ] [ "boot" "loader" "asahi" "m1n1" "extraOptions" ])
    (lib.mkRenamedOptionModule [ "boot" "m1n1CustomLogo" ] [ "boot" "loader" "asahi" "m1n1" "customLogo" ])
  ];

  options.boot.loader.asahi = {
    m1n1 = {
      package = lib.mkPackageOption pkgs "Custom package override for Asahi m1n1" {
        default = pkgs.m1n1.override {
          isRelease = true;
          withTools = false;
          customLogo = config.boot.loader.asahi.m1n1.customLogo;
        };
      };

      extraOptions = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Append extra options to the m1n1 boot binary. Might be useful for fixing
          display problems on Mac minis.
          https://github.com/AsahiLinux/m1n1/issues/159
        '';
      };

      customLogo = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Custom logo to build into m1n1. The path must point to a 256x256 PNG.
        '';
      };
    };

    uboot = {
      package = lib.mkPackageOption pkgs "Custom package override for Asahi U-Boot" {
        default = pkgs.uboot-asahi.override {
          m1n1 = config.boot.loader.asahi.m1n1.package;
        };
      };
    };
  };
}
