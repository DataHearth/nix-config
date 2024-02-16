{ stdenv, vscode-utils, lib, ... }:
vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = let
    sources = {
      "x86_64-linux" = {
        arch = "linux-x64";
        sha256 = "d9cd2d1ff3250cea9ec9f7dc57c642cb8c28a2005371fd460ae3cf3bc2576967";
      };
      "x86_64-darwin" = {
        arch = "darwin-x64";
        sha256 = "7aebc62253bbf77d4de7a4790562aedc5f67484a0381ff835e4ec7825d6a494c";
      };
      "aarch64-linux" = {
        arch = "linux-arm64";
        sha256 = "1j1xlvbg3nrfmdd9zm6kywwicdwdkrq0si86lcndaii8m7sj5pfp";
      };
      "aarch64-darwin" = {
        arch = "darwin-arm64";
        sha256 = "746a481c28677eb41bc51643ba8022e229a04adcb23ddc5dbd34379649cc62ed";
      };
    };
  in {
    name = "ruff";
    publisher = "charliermarsh";
    version = "2024.4.0";
  } // sources.${stdenv.system};
  meta = {
    license = lib.licenses.mit;
    changelog = "https://marketplace.visualstudio.com/items/charliermarsh.ruff/changelog";
    description = "A Visual Studio Code extension with support for the Ruff linter.";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=charliermarsh.ruff";
    homepage = "https://github.com/astral-sh/ruff-vscode";
    maintainers = [ lib.maintainers.azd325 ];
  };
}
