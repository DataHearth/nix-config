final: prev: with prev; {
  nosql-workbench = callPackage ./nosql-workbench.nix { };
  vscode-extensions = lib.recursiveUpdate vscode-extensions (callPackage ./vscode-extensions { });
}
