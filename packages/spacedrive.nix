{ appimageTools, lib, fetchurl, gtk3, gsettings-desktop-schemas, makeDesktopItem }:
let
  pname = "spacedrive";
  version = "0.2.3";
  name = "${pname}-${version}";
  description = "Spacedrive is an open source cross-platform file explorer, powered by a virtual distributed filesystem written in Rust.";
  src = fetchurl {
    name = pname;
    url = "https://github.com/spacedriveapp/spacedrive/releases/download/${version}/Spacedrive-linux-x86_64.AppImage";
    sha256 = "1b2xkpdxw93cnmylq39915m8a3wmwwf1gyqi83qszpdigb31n5db";
  };
  appimageContents = appimageTools.extract {
    inherit name src;
  };
in
appimageTools.wrapType2 {
  inherit name src;

  extraPkgs = appimageTools.defaultFhsEnvArgs.multiPkgs;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/com.${pname}.desktop -t $out/share/applications
    install -Dm444 ${appimageContents}/${pname}.png -t $out/share/pixmaps
    substituteInPlace $out/share/applications/com.${pname}.desktop --replace 'Exec=usr/bin/spacedrive' 'Exec=${name}'
  '';
}
