{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  runCommand,
  openssl,
  curl,
  libxml2,
  webkitgtk_4_1,
  gtk3,
  gdk-pixbuf,
  libsoup_3,
  glib,
  glib-networking,
  libnotify,
  dbus,
  iproute2,
  procps,
  coreutils,
  gnutar,
}:

stdenv.mkDerivation {
  pname = "f5vpn-ng";
  version = "7272.0.0.2";

  # GTK/WebKit rewrite that replaces both the Qt f5vpn client and f5epi:
  # Airbus's portal now serves this same package at the f5vpn .deb and the
  # f5epi .rpm URLs. The public /download/ endpoint needs no auth.
  # Refresh the hash with ./update.sh f5vpn-ng.
  src = fetchurl {
    url = "https://axess.airbus.com/public/download/linux_f5vpn.x86_64.deb";
    hash = "sha256-U8b8Q2QyALkKrD1KCyHhY7biNdEbUbzhaVrsCDz3kFk=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    # Replaces the libssl/libcrypto bundled in usr/lib/f5vpn-ng: that
    # libcrypto is built without OCSP, so once autoPatchelf picked it for the
    # GTK client, nixpkgs' libssl (pulled in by curl and WebKit) failed to load
    # on OCSP_RESPID_free. Same 3.x ABI, so the native helpers take it too.
    openssl
    curl
    # Linked against libxml2.so.2; nixpkgs libxml2 2.15 ships libxml2.so.16
    # with the same 2.x ABI.
    (runCommand "libxml2-so2-compat" { } ''
      mkdir -p $out/lib
      ln -s ${lib.getLib libxml2}/lib/libxml2.so.16 $out/lib/libxml2.so.2
    '')
    webkitgtk_4_1
    gtk3
    gdk-pixbuf
    libsoup_3
    glib
    glib-networking
    libnotify
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 usr/bin/f5vpn-ng -t $out/bin
    cp -r usr/share $out/

    # The client spawns everything from /usr/share/f5vpn-ng, which tmpfiles
    # points at $out/share/f5vpn-ng. svpn has to run setuid root, so the copy
    # there is swapped for the security wrapper and the real binary moves out
    # of the way to be the wrapper's source.
    install -Dm755 $out/share/f5vpn-ng/svpn -t $out/libexec/f5vpn-ng
    ln -sf /run/wrappers/bin/svpn $out/share/f5vpn-ng/svpn

    # f5PolicyServer dlopens the OESIS inspector that the gateway downloads
    # into ~/.F5Networks/Inspectors at check time; autoPatchelf never sees it,
    # so its libstdc++/libgcc_s (and dbus for the checks) come from here.
    wrapProgram $out/share/f5vpn-ng/f5PolicyServer \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          stdenv.cc.cc.lib
          dbus
        ]
      }"

    substituteInPlace $out/share/applications/f5vpn-ng.desktop \
      --replace-fail "/usr/bin/f5vpn-launcher" "$out/bin/f5vpn-ng" \
      --replace-fail "DBusActivatable=true" "DBusActivatable=false"
    install -Dm444 $out/share/f5vpn-ng/com.f5.f5vpn.service -t $out/share/dbus-1/services
    substituteInPlace $out/share/dbus-1/services/com.f5.f5vpn.service \
      --replace-fail "/usr/bin/f5vpn-launcher" "$out/bin/f5vpn-ng"

    # Paths compiled into the binaries. The window and tray icons are only
    # looked up under /usr/share/icons/hicolor. /usr/bin/sudo and /sbin/ip are how the
    # client adds host routes (allowed by the sudo rule in the f5 module);
    # sudo/kill/pkill stop the root-owned svpn; f5PolicyServer wants tar at
    # /usr/bin/tar or /usr/local/bin/tar; svpn writes its pid under
    # /usr/local/lib/F5Networks.
    install -Dm444 /dev/stdin $out/lib/tmpfiles.d/f5vpn-ng.conf <<EOF
    d /usr/share 0755 root root -
    L+ /usr/share/f5vpn-ng - - - - $out/share/f5vpn-ng
    d /usr/share/icons 0755 root root -
    L+ /usr/share/icons/hicolor - - - - $out/share/icons/hicolor
    d /usr/bin 0755 root root -
    L+ /usr/bin/sudo - - - - /run/wrappers/bin/sudo
    L+ /usr/bin/pkill - - - - ${procps}/bin/pkill
    L+ /bin/kill - - - - ${coreutils}/bin/kill
    d /sbin 0755 root root -
    L+ /sbin/ip - - - - ${iproute2}/bin/ip
    d /usr/local/bin 0755 root root -
    L+ /usr/local/bin/tar - - - - ${gnutar}/bin/tar
    d /usr/local/lib/F5Networks/SSLVPN/var/run 0755 root root -
    EOF

    runHook postInstall
  '';

  # The hook would also wrap libexec/f5vpn-ng/svpn in a shell script, which
  # the setuid wrapper would then run as root with the caller's environment.
  dontWrapGApps = true;
  postFixup = ''
    wrapGApp $out/bin/f5vpn-ng
  '';

  meta = with lib; {
    description = "F5 BIG-IP APM VPN client with endpoint inspection (GTK/WebKit)";
    homepage = "https://www.f5.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "f5vpn-ng";
  };
}
