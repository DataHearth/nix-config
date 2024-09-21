{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.hm.vscode;

  enable = lib.mkEnableOption "vscode";
  additional_extensions = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    description = "List of additional extensions to install";
    example = [ (lib.literalExpression "pkgs.vscode-extensions.golang.go") ];
  };
in
{
  options.hm.vscode = {
    inherit enable additional_extensions;
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      mutableExtensionsDir = false;
      extensions = with pkgs.vscode-extensions; [
        github.github-vscode-theme

        redhat.vscode-yaml
        redhat.vscode-xml

        svelte.svelte-vscode
        sumneko.lua
        rust-lang.rust-analyzer
        golang.go
        dart-code.flutter
        bbenoist.nix

        ms-vscode.cmake-tools
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
        ms-python.python
        ms-vscode.makefile-tools
        ms-azuretools.vscode-docker
        ms-python.vscode-pylance
        # ms-vscode.cpptools

        njpwerner.autodocstring
        mikestead.dotenv
        tamasfe.even-better-toml
        formulahendry.auto-close-tag
        formulahendry.auto-rename-tag
        grapecity.gc-excelviewer
        dbaeumer.vscode-eslint
        eamodio.gitlens
        wholroyd.jinja
        skellock.just
        esbenp.prettier-vscode
        bradlc.vscode-tailwindcss
        vscode-icons-team.vscode-icons
        zxh404.vscode-proto3
        twxs.cmake
        aaron-bond.better-comments
        alexisvt.flutter-snippets
        christian-kohler.npm-intellisense
        ecmel.vscode-html-css
        charliermarsh.ruff
        earthly.earthfile-syntax-highlighting
        davidanson.vscode-markdownlint
        samuelcolvin.jinjahtml
      ];
      userSettings = lib.importJSON ./settings.json;
      languageSnippets = {
#        go = lib.importJSON ./snippets/go.json;
      };
    };
  };
}
