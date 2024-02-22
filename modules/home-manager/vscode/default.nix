{ pkgs, lib, ... }:
{
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    extensions = with pkgs.vscode-extensions; [
      github.github-vscode-theme
      github.copilot-chat
      github.copilot

      redhat.vscode-yaml
      redhat.vscode-xml

      svelte.svelte-vscode
      sumneko.lua
      rust-lang.rust-analyzer
      golang.go
      dart-code.flutter
      bbenoist.nix

      # ms-vsliveshare.vsliveshare
      # ms-vscode.cpptools
      ms-vscode.cmake-tools
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-containers
      ms-python.python
      ms-vscode.makefile-tools
      ms-azuretools.vscode-docker
      ms-python.vscode-pylance

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
    ];
    userSettings = lib.importJSON ./settings.json;
    languageSnippets = {
      go = lib.importJSON ./snippets/go.json;
    };
  };
}
