{ pkgs, ... }:
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

      ms-vsliveshare.vsliveshare
      ms-vscode.cpptools
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

      # Overlay
      charliermarsh.ruff
    ];
    userSettings = {
      "telemetry.telemetryLevel" = "off";
      "redhat.telemetry.enabled" = false;

      "workbench.colorTheme" = "GitHub Dark";
      "workbench.iconTheme" = "vscode-icons";
      "workbench.startupEditor" = "newUntitledFile";
      "workbench.editorAssociations" = {
        "*.ipynb" = "jupyter-notebook";
      };

      "files.autoSave" = "afterDelay";

      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;

      "editor.fontLigatures" = true;
      "editor.fontFamily" = "FiraCode Nerd Font";
      "editor.tabSize" = 2;
      "editor.inlineSuggest.enabled" = true;
      "editor.suggestSelection" = "first";
      "editor.formatOnSave" = true;
      "editor.bracketPairColorization.enabled" = true;
      "editor.guides.bracketPairs" = "active";
      "editor.linkedEditing" = true;
      "editor.codeActionsOnSave" = {
        "source.fixAll" = "explicit";
        "source.organizeImports" = "explicit";
      };

      "update.showReleaseNotes" = false;

      "security.workspace.trust.untrustedFiles" = "newWindow";

      "files.associations" = {
        "LICENSE" = "plaintext";
        "*.mdx" = "markdown";
      };

      "github.gitProtocol" = "ssh";

      "go.toolsManagement.autoUpdate" = true;

      "eslint.validate" = ["javascript" "typescript"];

      "git.confirmSync" = false;
      "git.autofetch" = "all";

      "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";

      "vsicons.dontShowNewVersionMessage" = true;

      "[dart]" = {
        "editor.rulers" = [80];
        "editor.selectionHighlight" = false;
        "editor.suggestSelection" = "first";
        "editor.tabCompletion" = "onlySnippets";
        "editor.wordBasedSuggestions" = "off";
      };

      "[python]" = {
        "editor.defaultFormatter" = "charliermarsh.ruff";
        "editor.codeActionsOnSave" = {
          "source.fixAll" = "explicit";
          "source.organizeImports" = "explicit";
        };
        "gitlens.codeLens.symbolScopes" = ["!Module"];
        "editor.wordBasedSuggestions" = "off";
        "editor.tabSize" = 4;
      };
      "python.analysis.inlayHints.functionReturnTypes" = true;
      "python.analysis.inlayHints.variableTypes" = true;
      "python.analysis.typeCheckingMode" = "basic";

      "notebook.cellToolbarLocation" = {
        "default" = "right";
        "jupyter-notebook" = "left";
      };

      "[javascript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      "[typescript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "typescript.updateImportsOnFileMove.enabled" = "always";

      "[vue]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      "[rust]" = {
        "editor.tabSize" = 4;
      };

      "[json]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      "[html]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      "[handlebars]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      "[jsonc]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      "gitlens.advanced.messages" = {
        "suppressGitMissingWarning" = true;
      };

      "[markdown]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      "[yaml]" = {
        "editor.defaultFormatter" = "redhat.vscode-yaml";
      };
      "yaml.schemas" = {
        "https =//goreleaser.com/static/schema.json" = ".goreleaser.yml";
        "https =//squidfunk.github.io/mkdocs-material/schema.json" = "mkdocs.yml";
        "https =//json.schemastore.org/github-workflow.json" = [
          ".gitea/workflows/*.yaml"
          ".gitea/workflows/*.yml"
        ];
      };
      "[css]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      "[svelte]" = {
        "editor.defaultFormatter" = "svelte.svelte-vscode";
      };
      "svelte.enable-ts-plugin" = true;
      "svelte.plugin.svelte.defaultScriptLanguage" = "ts";

      "github.copilot.enable" = {
        "*" = true;
        "plaintext" = false;
        "markdown" = true;
        "scminput" = false;
        "yaml" = true;
      };
      "editor.unicodeHighlight.allowedCharacters" = {
        "é" = true;
        "è" = true;
        "à" = true;
        "ô" = true;
      };
      "workbench.editor.empty.hint" = "hidden";
      "remote.SSH.remotePlatform" = {
        "10.0.0.3" = "linux";
        "cronos-debian" = "linux";
        "oncopole" = "linux";
      };
      "[jinja-html]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "liveServer.settings.donotShowInfoMsg" = true;
      "[dart][python]" = {
        "editor.wordBasedSuggestions" = "off";
      };
      "window.dialogStyle" = "custom";
      "settingsSync.ignoredSettings" = ["editor.fontFamily"];
    };
  };
}
