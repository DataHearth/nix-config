{
  lib,
  config,
  ...
}:
let
  cfg = config.home_modules.zen-browser;
in
{
  options.home_modules.zen-browser = {
    enable = lib.mkEnableOption "zen-browser";

    searchEngines = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Search engines to add to the default profile.";
    };

    defaultSearchEngine = lib.mkOption {
      type = lib.types.str;
      description = "Name of the search engine to set as default in the default profile.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;

      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFormHistory = true;
        PasswordManagerEnabled = false;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        FirefoxSuggest = {
          WebSuggestions = false;
          SponsoredSuggestions = false;
          ImproveSuggest = false;
        };
        EnableTrackingProtection = {
          Value = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        ExtensionSettings =
          let
            ext = id: url: {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${url}/latest.xpi";
              installation_mode = "force_installed";
            };
            extDisabled = id: url: {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${url}/latest.xpi";
              installation_mode = "normal_installed";
            };
          in
          {
            "uBlock0@raymondhill.net" = ext "uBlock0@raymondhill.net" "ublock-origin";
            "jid1-MnnxcxisBPnSXQ@jetpack" = ext "jid1-MnnxcxisBPnSXQ@jetpack" "privacy-badger17";
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" =
              ext "{446900e4-71c2-419f-a6a7-df9c091e268b}" "bitwarden-password-manager";
            "addon@darkreader.org" = ext "addon@darkreader.org" "darkreader";
            "{cf3dba12-a848-4f68-8e2d-f9fadc0721de}" =
              ext "{cf3dba12-a848-4f68-8e2d-f9fadc0721de}" "google-lighthouse";
            "78272b6fa58f4a1abaac99321d503a20@proton.me" =
              extDisabled "78272b6fa58f4a1abaac99321d503a20@proton.me" "proton-pass";
            "vpn@proton.ch" = ext "vpn@proton.ch" "proton-vpn-firefox-extension";
            "sponsorBlocker@ajay.app" = ext "sponsorBlocker@ajay.app" "sponsorblock";
            "fr-dicollecte@dictionaries.addons.mozilla.org" =
              ext "fr-dicollecte@dictionaries.addons.mozilla.org" "dictionnaire-fran%C3%A7ais1";
            "ef-french-simplified-orthograph@dictionaries.addons.mozilla.org" =
              ext "ef-french-simplified-orthograph@dictionaries.addons.mozilla.org" "corecteur-ortografe-simplifiee";
            "langpack-fr@firefox.mozilla.org" = ext "langpack-fr@firefox.mozilla.org" "francais-language-pack";
          };
      };

      profiles.default = {
        id = 0;
        isDefault = true;
        path = "gz71a4fv.Default Profile";

        mods = [
          "ad97bb70-0066-4e42-9b5f-173a5e42c6fc" # SuperPins
        ];

        search = {
          default = cfg.defaultSearchEngine;
          force = true;
          engines = lib.recursiveUpdate {
            "google".metaData.hidden = true;
            "bing".metaData.hidden = true;
          } cfg.searchEngines;
        };

        settings = {
          # Startup: restore session
          "browser.startup.page" = 3;
          "browser.shell.checkDefaultBrowser" = true;

          # Spellcheck
          "layout.spellcheckDefault" = 1;
          "spellchecker.dictionary" = "fr,en-US";

          # Search suggestions
          "browser.search.suggest.enabled" = true;
          "browser.urlbar.suggest.searches" = true;

          # Sidebar + topbar layout
          "zen.view.use-single-toolbar" = false;

          # Fractional scaling breaks extension popups on wlroots compositors
          # (bugzilla#1849109). Disable until upstream fix lands.
          "widget.wayland.fractional-scale.enabled" = false;

          # Disable all saving/autofill
          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "browser.formfill.enable" = false;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;

          # Telemetry
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "browser.ping-centre.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
        };

        containers = { };
      };
    };
  };
}
