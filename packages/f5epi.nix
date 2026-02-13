{
  lib,
  stdenv,
  fetchurl,
  rpmextract,
  autoPatchelfHook,
  makeWrapper,
  xkeyboard-config,
  libx11,
  libxext,
  libxrender,
  libxcb,
  libxi,
  libsm,
  libice,
  fontconfig,
  freetype,
  glib,
  libGL,
  dbus,
  cacert,
  gnutar,
}:

stdenv.mkDerivation {
  pname = "f5epi";
  version = "7183.2020.0826.1";

  src = fetchurl {
    url = "https://vpn.brown.edu/public/download/linux_f5epi.x86_64.rpm";
    hash = "sha256-Xd5a2ePaFNGOAx90P+CvBdj516qP2uDVsXN9z+pc6sA=";
  };

  nativeBuildInputs = [
    rpmextract
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    libx11
    libxext
    libxrender
    libxcb
    libxi
    libsm
    libice
    fontconfig
    freetype
    glib
    libGL
  ];

  unpackPhase = ''
    rpmextract $src
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/f5
    cp -r opt/f5/epi $out/opt/f5/

    mkdir -p $out/bin
    makeWrapper $out/opt/f5/epi/f5epi $out/bin/f5epi \
      --set QT_XKB_CONFIG_ROOT "${xkeyboard-config}/share/X11/xkb" \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
      --set SSL_CERT_DIR "${cacert}/etc/ssl/certs" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ dbus stdenv.cc.cc.lib ]}" \
      --run "mkdir -p \$HOME/.F5Networks/Inspectors"
    ln -s $out/opt/f5/epi/f5PolicyServer $out/bin/f5PolicyServer

    # Desktop entry
    install -Dm444 opt/f5/epi/com.f5.f5epi.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/com.f5.f5epi.desktop \
      --replace-fail "/opt/f5/epi/f5epi" "$out/bin/f5epi" \
      --replace-fail "DBusActivatable=true" "DBusActivatable=false" \
      --replace-fail "MimeType=x-scheme-handler/f5-epi;" "MimeType=x-scheme-handler/f5-epi;x-scheme-handler/f5epi;"

    # D-Bus service
    install -Dm444 opt/f5/epi/com.f5.f5epi.service -t $out/share/dbus-1/services
    substituteInPlace $out/share/dbus-1/services/com.f5.f5epi.service \
      --replace-fail "/opt/f5/epi/f5epi" "$out/bin/f5epi"

    # f5PolicyServer expects tar at /usr/bin/tar or /usr/local/bin/tar
    install -Dm444 /dev/stdin $out/lib/tmpfiles.d/f5epi.conf <<EOF
    d /usr/local/bin 0755 root root -
    L+ /usr/local/bin/tar - - - - ${gnutar}/bin/tar
    EOF

    # Icons
    for icon in opt/f5/epi/logos/*.png; do
      size=$(basename "$icon" .png)
      install -Dm444 "$icon" "$out/share/icons/hicolor/''${size}/apps/f5epi.png"
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "F5 Endpoint Inspection plugin for BIG-IP APM";
    homepage = "https://www.f5.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
