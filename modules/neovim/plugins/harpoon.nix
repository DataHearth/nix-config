{ vimUtils, fetchFromGithub }:
{
  enable = true;
  package = vimUtils.buildVimPlugins {
    pname = "harpoon";
    version = "26-01-2024";
    src = fetchFromGithub {
      owner = "ThePrimeagen";
      repo = "harpoon";
      rev = "a38be6e0dd4c6db66997deab71fc4453ace97f9c";
      hash = "sha256-XXXXXXXXXXXXX";
    };
  };
  enableTelescope = true;
  keymaps = {
    navNext = "<C-hn>";
    navPrev = "<C-hp>";
    toggleQuickMenu = "<C-e>";
  };
}
