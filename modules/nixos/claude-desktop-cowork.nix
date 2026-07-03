{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.claude-desktop-cowork;
in
{
  options.nixos_modules.claude-desktop-cowork = {
    enable = lib.mkEnableOption "Claude Desktop Cowork host support";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "datahearth" ];
      description = ''
        Users granted the `kvm` group, so they can open /dev/kvm and
        /dev/vhost-vsock read-write — both required for Cowork's agent VM.
      '';
    };

    ovmf = lib.mkOption {
      type = lib.types.package;
      default = pkgs.OVMF;
      defaultText = lib.literalExpression "pkgs.OVMF";
      description = ''
        OVMF package providing the Cowork VM's UEFI firmware. Its `firmware`
        (OVMF_CODE.fd) and `variables` (OVMF_VARS.fd) are symlinked into the
        Debian path the app hardcodes.
      '';
    };

    virtiofsd = lib.mkOption {
      type = lib.types.package;
      default = pkgs.virtiofsd;
      defaultText = lib.literalExpression "pkgs.virtiofsd";
      description = ''
        virtiofsd binary that shares host folders into the Cowork VM. The app
        bundles its own copy but only falls back to it on Ubuntu 22.x; every
        other distro (NixOS included) it probes `/usr/libexec/virtiofsd`, so we
        symlink this binary there.
      '';
    };
  };

  # Claude Desktop's "Cowork" tab boots its agent in a qemu micro-VM. qemu is on
  # the claude-desktop wrapper PATH (see packages/claude-desktop.nix); this
  # module supplies the host-side pieces the app can't provide for itself. Note
  # the app *bundles* a virtiofsd but only uses it on Ubuntu 22.x, so on NixOS
  # we still have to hand it one at its hardcoded probe path (see below).
  config = lib.mkIf cfg.enable {
    # vhost-vsock backs the host<->guest control socket.
    boot.kernelModules = [ "vhost_vsock" ];

    # Cowork's "local" (non-VM) mode runs the agent as a Claude Code CLI the app
    # downloads to ~/.config/Claude/claude-code/<ver>/claude and execs directly on
    # the host. That's an FHS-linked Node single-file binary; NixOS's stub-ld
    # rejects it ("Could not start dynamically linked executable", exit 127 ->
    # "Claude Code crashed"). nix-ld provides a real /lib64 loader + libs so it
    # runs unmodified (patchelf corrupts the embedded SEA blob; can't rewrite it).
    # VM-sandbox mode is unaffected — that CLI runs inside the Ubuntu guest, which
    # has its own loader. NIX_LD_LIBRARY_PATH is picked up from a fresh login
    # session, so re-login after switching for local mode to work.
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib # libstdc++.so.6, libgcc_s.so.1
      zlib
    ];

    # The app probes hardcoded Debian paths with no override, so materialise the
    # host-side bits there. OVMF: it derives the (writable, copied-per-VM) VARS
    # template from the CODE path by name, so both must sit together. virtiofsd:
    # it looks at /usr/libexec/virtiofsd (then /usr/bin/virtiofsd), never its own
    # bundled copy unless the host is Ubuntu 22.x.
    systemd.tmpfiles.rules = [
      "L+ /usr/share/OVMF/OVMF_CODE.fd - - - - ${cfg.ovmf.firmware}"
      "L+ /usr/share/OVMF/OVMF_VARS.fd - - - - ${cfg.ovmf.variables}"
      "L+ /usr/libexec/virtiofsd - - - - ${lib.getExe cfg.virtiofsd}"
    ];

    # /dev/vhost-vsock is root-only by default; hand it to the kvm group.
    services.udev.extraRules = ''
      KERNEL=="vhost-vsock", GROUP="kvm", MODE="0660"
    '';

    # rw on /dev/kvm + /dev/vhost-vsock (the app opens both with R_OK|W_OK).
    users.users = lib.genAttrs cfg.users (_: {
      extraGroups = [ "kvm" ];
    });
  };
}
