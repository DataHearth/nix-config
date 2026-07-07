# Official Anthropic Claude Desktop for Linux (beta, since 2026-06-30).
#
# nixpkgs has no `claude-desktop`, so this repackages Anthropic's upstream .deb
# (from their apt repo). It's a vendored-Electron/Chromium app: extract the deb,
# autoPatchelf the bundled Electron binary + helpers, integrate GTK (schemas,
# pixbuf, portals) via wrapGAppsHook3, and wrap the launcher to force Wayland.
# Auto-detect otherwise leaves it on XWayland under Hyprland, which bitmap-
# upscales to a blurry window on fractional scaling. Toggle with `useWayland`.
#
# Cowork runs its agent in a qemu micro-VM (resources/smol-bin.x64.img). With
# `cowork = true` (default) qemu is put on the app's PATH here; the host side —
# OVMF firmware and a virtiofsd binary at the Debian paths the app hardcodes
# (its own bundled virtiofsd is only used on Ubuntu 22.x), the vhost_vsock
# module, and rw on /dev/kvm + /dev/vhost-vsock — lives in the NixOS config
# (modules/nixos/claude-desktop-cowork.nix). Computer Use and dictation aren't
# in the Linux beta.
#
# Update: run ./update.sh claude-desktop [version] to bump `version` and refresh
# both .deb hashes (pulled from the apt Packages index). Defaults to the latest
# version in the index when none is given.
{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  # DT_NEEDED of the vendored Electron binary and bundled helpers
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libgbm,
  nspr,
  nss,
  pango,
  systemd,
  # bundled virtiofsd (Cowork micro-VM helper)
  libseccomp,
  libcap_ng,
  libX11,
  libxcb,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxkbcommon,
  # runtime dlopen deps (baked into rpath so Chromium can load them lazily)
  wayland,
  libglvnd,
  vulkan-loader,
  libxshmfence,
  fontconfig,
  freetype,
  libpulseaudio,
  pipewire,
  libsecret,
  libnotify,
  libXi,
  libXcursor,
  libXrender,
  libXScrnSaver,
  libXtst,
  # Cowork micro-VM: qemu goes on the app's PATH (virtiofsd is bundled)
  qemu_kvm,
  # Code tab: put direnv/nix (+ a base bash/coreutils) on the app's PATH so the
  # shared SessionStart/CwdChanged devShell hook and Claude's own `nix`/`direnv`
  # calls resolve, whatever PATH the graphical session hands the app. See
  # modules/home-manager/claude-code/load-direnv.sh.
  direnv,
  nix,
  bash,
  coreutils,
  useWayland ? true,
  cowork ? true,
}:
let
  version = "1.18286.2";
  base = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop";
  srcs = {
    x86_64-linux = fetchurl {
      url = "${base}/claude-desktop_${version}_amd64.deb";
      sha256 = "56fa5de053e0a68dc7583677857bedcf4219b19d90201400e0237b7d74d512f1";
    };
    aarch64-linux = fetchurl {
      url = "${base}/claude-desktop_${version}_arm64.deb";
      sha256 = "38c65a1226dccc75a6b2418b9d4c064f4f9dc5331f89608aedd554d87d529ba3";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "claude-desktop";
  inherit version;

  src =
    srcs.${stdenvNoCC.hostPlatform.system}
      or (throw "claude-desktop: unsupported system ${stdenvNoCC.hostPlatform.system}");

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgbm
    nspr
    nss
    pango
    systemd
    libseccomp
    libcap_ng
    libX11
    libxcb
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxkbcommon
  ];

  runtimeDependencies = [
    wayland
    libglvnd
    vulkan-loader
    libxshmfence
    fontconfig
    freetype
    libpulseaudio
    pipewire
    libsecret
    libnotify
    libgbm
    libxkbcommon
    libXi
    libXcursor
    libXrender
    libXScrnSaver
    libXtst
  ];

  # We build our own wrapper below; let wrapGAppsHook3 collect its env (GTK
  # modules, GSETTINGS/GIO schemas, pixbuf loaders) into gappsWrapperArgs
  # instead of wrapping the raw binary itself.
  dontWrapGApps = true;
  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    # dpkg-deb -x restores chrome-sandbox's setuid bit, which the build sandbox
    # forbids. Pipe the data tarball through tar instead: as non-root it drops
    # setuid (the store strips it anyway; NixOS uses the userns sandbox).
    dpkg-deb --fsys-tarfile $src | tar -x --no-same-owner --no-same-permissions
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin $out/share
    cp -r usr/lib/claude-desktop $out/lib/
    cp -r usr/share/applications $out/share/
    cp -r usr/share/icons $out/share/

    # The bundled ANGLE (libEGL.so) dlopens the *native* libEGL.so.1 by soname to
    # reach the GPU; that dispatch lib ships in libglvnd (NOT /run/opengl-driver,
    # which only has the mesa vendor libGLX_mesa). Without it on the search path
    # ANGLE's eglInitialize fails, Chromium falls back to use-gl=disabled, and the
    # whole UI composites in software (janky modals). Give the loader libglvnd for
    # the glvnd dispatch libs plus the impure driver dir it dispatches into.
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libglvnd ]}:/run/opengl-driver/lib" \
      --prefix PATH : ${lib.makeBinPath [ direnv nix bash coreutils ]} \
      ${lib.optionalString cowork ''--prefix PATH : ${lib.makeBinPath [ qemu_kvm ]} ''}\
      ${lib.optionalString useWayland ''--add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime=true" ''}

    runHook postInstall
  '';

  meta = {
    description = "Official Anthropic desktop application for Claude.ai (Linux beta)";
    homepage = "https://claude.ai/download";
    downloadPage = "https://claude.com/download";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "claude-desktop";
  };
}
