{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.blue-yeti;

  # USBDEVFS_RESET on the usbfs node, which is a real port reset + re-enumeration
  # (unlike a driver unbind/bind, which leaves the port state untouched and so
  # does not recover a device that is wedged below the driver). Needs an ioctl,
  # hence a binary rather than a shell one-liner; the udev rule below hands the
  # seat user write access to the node so it runs without root.
  usb-port-reset = pkgs.writeCBin "usb-port-reset" ''
    #include <errno.h>
    #include <fcntl.h>
    #include <linux/usbdevice_fs.h>
    #include <stdio.h>
    #include <string.h>
    #include <sys/ioctl.h>
    #include <unistd.h>

    int main(int argc, char **argv) {
      if (argc != 2) {
        fprintf(stderr, "usage: usb-port-reset /dev/bus/usb/BBB/DDD\n");
        return 2;
      }
      int fd = open(argv[1], O_WRONLY);
      if (fd < 0) {
        fprintf(stderr, "open %s: %s\n", argv[1], strerror(errno));
        return 1;
      }
      int rc = ioctl(fd, USBDEVFS_RESET, 0);
      int saved = errno;
      close(fd);
      if (rc < 0) {
        fprintf(stderr, "USBDEVFS_RESET %s: %s\n", argv[1], strerror(saved));
        return 1;
      }
      return 0;
    }
  '';

  # Deliberately NOT services.udev.extraRules: that lands in 99-local.rules, and
  # systemd's 73-seat-late.rules is what turns TAG+="uaccess" into an ACL
  # (RUN{builtin}+="uaccess", gated on TAG=="uaccess"). udev merges every rules
  # directory and sorts by filename, so a tag set at 99 is set after 73 already
  # ran and the builtin never fires — the node stays root-only. Any number below
  # 73 works; 60 matches what other uaccess-using rule files use.
  #
  # add|change, not add alone: NixOS activation reloads udev and re-triggers with
  # --action=change, so matching both means a switch is enough and the device
  # does not have to be replugged.
  udevRules = pkgs.writeTextFile {
    name = "blue-yeti-udev-rules";
    destination = "/etc/udev/rules.d/60-blue-yeti.rules";
    text = ''
      ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="${cfg.vendorId}", ATTR{idProduct}=="${cfg.productId}", TEST=="power/control", ATTR{power/control}="on", TAG+="uaccess"
    '';
  };

  yeti-reset = pkgs.writeShellApplication {
    name = "yeti-reset";
    runtimeInputs = [ usb-port-reset ];
    text = ''
      vid="${cfg.vendorId}"
      pid="${cfg.productId}"

      # Resolved from the bus every run: the port path (1-2.1.4) follows which
      # socket it is plugged into and the devnum changes on every re-enumeration,
      # which for this device is constantly.
      target=""
      for dev in /sys/bus/usb/devices/*; do
        [ -r "$dev/idVendor" ] && [ -r "$dev/idProduct" ] || continue
        read -r vendor < "$dev/idVendor"
        read -r product < "$dev/idProduct"
        if [ "$vendor" = "$vid" ] && [ "$product" = "$pid" ]; then
          target="$dev"
          break
        fi
      done

      if [ -z "$target" ]; then
        echo "yeti-reset: no USB device $vid:$pid on the bus." >&2
        echo "It is not enumerated at all, so there is no port to reset — replug the cable." >&2
        exit 1
      fi

      read -r busnum < "$target/busnum"
      read -r devnum < "$target/devnum"
      node="$(printf '/dev/bus/usb/%03d/%03d' "$busnum" "$devnum")"

      echo "yeti-reset: resetting $(basename "$target") at $node"
      usb-port-reset "$node"
      echo "yeti-reset: done"
    '';
  };
in
{
  options.nixos_modules.blue-yeti = {
    enable = lib.mkEnableOption "Blue Yeti USB microphone recovery tooling";

    vendorId = lib.mkOption {
      type = lib.types.str;
      default = "046d";
      description = "USB idVendor of the microphone, lowercase hex without 0x.";
    };

    productId = lib.mkOption {
      type = lib.types.str;
      default = "0ab7";
      description = "USB idProduct of the microphone, lowercase hex without 0x.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.packages = [ udevRules ];

    environment.systemPackages = [
      yeti-reset
      pkgs.uhubctl
    ];
  };
}
