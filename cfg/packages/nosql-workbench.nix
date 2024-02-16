{ appimageTools, lib, fetchurl, gtk3, gsettings-desktop-schemas, makeDesktopItem, ... }:
let
  pname = "nosql-workbench";
  version = "3.11.0";
  name = "${pname}-${version}";

  src = fetchurl {
    name = pname;
    url = "https://s3.amazonaws.com/nosql-workbench/NoSQL%20Workbench-linux-${version}.AppImage";
    sha256 = "7033926e10041411ef025bb14f1a95a6f6b51894a51618a8cf345fb8ce0c2b97";
  };

  appimageContents = appimageTools.extract {
    inherit name src;
  };

  desktopItem = makeDesktopItem {
    name = "NoSQL Workbench";
    exec = "nosql-workbench";
    comment = "NoSQL Workbench for Amazon DynamoDB is a cross-platform client-side application for modern database development and operations and is available for Windows and macOS.";
    desktopName = "NoSQL Workbench";
    genericName = "DB UI";
    categories = ["Development"];
  };
in
appimageTools.wrapType2 {
  inherit name src;

  profile = ''
    export XDG_DATA_DIRS=${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}:$XDG_DATA_DIRS
  '';

  multiPkgs = null; # no 32bit needed
  extraPkgs = appimageTools.defaultFhsEnvArgs.multiPkgs;

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications
    cp -r ${appimageContents}/usr/share/icons/ $out/share/
  '';
}
