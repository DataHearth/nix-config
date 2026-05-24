{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  runCommand,
  xkeyboard-config,
  openssl,
  libxml2,
  libxslt,
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
}:

stdenv.mkDerivation {
  pname = "f5vpn";
  version = "7261.2025.1009.1";

  # Sourced from Airbus's own BIG-IP APM portal so the client matches the
  # exact build their gateway (and EPI posture check) expects. Earlier
  # builds scavenged from third-party university portals (MTU's 7262.0.0.2)
  # emitted rtnetlink route attrs that kernel 6.18.34's strict validation
  # rejected ("netlink: 'svpn': attribute type N has an invalid length"),
  # flapping the tunnel. The public /download/ endpoint needs no auth.
  src = fetchurl {
    url = "https://axess.airbus.com/public/download/linux_f5vpn.x86_64.deb";
    hash = "sha256-LKkzN+oQQt8R5dNb85A/Bf8dcOiuJtFI1ob/98rQpxQ=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    openssl
    # Qt5WebKit (bundled in 7261.2025.1009.1, absent from the older client)
    # needs libxslt.so.1 and libxml2.so.2. nixpkgs libxml2 2.15 ships soname
    # libxml2.so.16 (meson build), so expose a .so.2 compat symlink — libxml2
    # holds a stable 2.x ABI, and WebKit is legacy here anyway (the client
    # uses QtWebEngine for the logon webview).
    libxslt
    (runCommand "libxml2-so2-compat" { } ''
      mkdir -p $out/lib
      ln -s ${lib.getLib libxml2}/lib/libxml2.so.16 $out/lib/libxml2.so.2
    '')
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

    # tunnelserver is an ELF binary but the .deb ships it without execute bits
    chmod +x $out/opt/f5/vpn/tunnelserver

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
    L+ /opt/f5/vpn/tunnelserver - - - - $out/opt/f5/vpn/tunnelserver
    d /usr/local/lib/F5Networks/SSLVPN/var/run 0755 root root -
    d /usr/local/ssl 0755 root root -
    L+ /usr/local/ssl/cert.pem - - - - ${cacert}/etc/ssl/certs/ca-bundle.crt
    L+ /usr/local/ssl/certs - - - - ${cacert}/etc/ssl/certs
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
