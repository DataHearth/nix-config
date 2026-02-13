{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  xkeyboard-config,
  openssl,
  libx11,
  libxrender,
  libxext,
  libxcb,
  libxkbcommon,
  libGL,
  libsm,
  libice,
  libxi,
  libxcomposite,
  libxdamage,
  libxfixes,
  libxrandr,
  libxtst,
  libxshmfence,
  libxkbfile,
  xcbutil,
  xcbutilwm,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcb-util-cursor,
  alsa-lib,
  brotli,
  dbus,
  expat,
  fontconfig,
  freetype,
  glib,
  harfbuzz,
  lcms2,
  minizip,
  mesa,
  nspr,
  nss,
  libopus,
  pcre2,
  snappy,
  libwebp,
  zlib,
  zstd,
  krb5,
  systemdMinimal,
  cacert,
  iproute2,
}:

stdenv.mkDerivation {
  pname = "f5vpn";
  version = "7262.0.0.2";

  src = fetchurl {
    url = "https://vpn-mgmt.it.mtu.edu/public/download/linux_f5vpn.x86_64.deb";
    hash = "sha256-W9mDSeW4PSfqCDlUPYg84vjZ5Uxc7mciC4uip+xT6g0=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    openssl
    libx11
    libxrender
    libxext
    libxcb
    libxkbcommon
    libGL
    libsm
    libice
    libxi
    libxcomposite
    libxdamage
    libxfixes
    libxrandr
    libxtst
    libxshmfence
    libxkbfile
    xcbutil
    xcbutilwm
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcb-util-cursor
    alsa-lib
    brotli
    dbus
    expat
    fontconfig
    freetype
    glib
    harfbuzz
    lcms2
    minizip
    mesa
    nspr
    nss
    libopus
    pcre2
    snappy
    libwebp
    zlib
    zstd
    krb5
    systemdMinimal
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/f5
    cp -r opt/f5/vpn $out/opt/f5/

    mkdir -p $out/bin
    makeWrapper $out/opt/f5/vpn/f5vpn $out/bin/f5vpn \
      --set QT_XKB_CONFIG_ROOT "${xkeyboard-config}/share/X11/xkb" \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
      --set SSL_CERT_DIR "${cacert}/etc/ssl/certs" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ dbus ]}"
    ln -s $out/opt/f5/vpn/f5vpn_launch_helper.sh $out/bin/f5vpn_launch_helper.sh
    ln -s $out/opt/f5/vpn/tunnelserver $out/bin/tunnelserver

    # Desktop entry
    install -Dm444 opt/f5/vpn/com.f5.f5vpn.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/com.f5.f5vpn.desktop \
      --replace-fail "/opt/f5/vpn/f5vpn" "$out/bin/f5vpn" \
      --replace-fail "DBusActivatable=true" "DBusActivatable=false"

    # Icons
    for icon in opt/f5/vpn/logos/*.png; do
      size=$(basename "$icon" .png)
      install -Dm444 "$icon" "$out/share/icons/hicolor/''${size}/apps/f5vpn.png"
    done

    # tmpfiles rule to symlink svpn at the hardcoded path f5vpn expects
    # Points to the security wrapper (setuid root) instead of the store path
    # because svpn needs root to create tun devices
    install -Dm444 /dev/stdin $out/lib/tmpfiles.d/f5vpn.conf <<EOF
    d /opt/f5/vpn 0755 root root -
    L+ /opt/f5/vpn/svpn - - - - /run/wrappers/bin/svpn
    EOF

    # Split tunnel fix: f5vpn routes 1.1.1.1 (DNS) through the tunnel,
    # breaking internet. This udev rule + systemd service removes that
    # route when tun0 appears, restoring normal DNS resolution.
    install -Dm555 /dev/stdin $out/libexec/f5vpn-fix-routes <<SCRIPT
    #!/bin/sh
    sleep 2
    ${iproute2}/bin/ip route del 1.1.1.1 dev tun0 2>/dev/null || true
    SCRIPT

    install -Dm444 /dev/stdin $out/lib/systemd/system/f5vpn-split-tunnel.service <<EOF
    [Unit]
    Description=Remove F5 VPN DNS route hijack for split tunneling
    After=network.target

    [Service]
    Type=oneshot
    ExecStart=$out/libexec/f5vpn-fix-routes
    EOF

    install -Dm444 /dev/stdin $out/lib/udev/rules.d/99-f5vpn-split-tunnel.rules <<EOF
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="tun0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="f5vpn-split-tunnel.service"
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "F5 VPN client for BIG-IP APM";
    homepage = "https://www.f5.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
